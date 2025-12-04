import asyncio
import base64
import hashlib
import json
import logging
import os
import time
from typing import Any, Dict, Optional

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi import Request
from fastapi.responses import JSONResponse
try:
    import redis.asyncio as aioredis  # type: ignore
except Exception:  # pragma: no cover - optional dependency
    aioredis = None

load_dotenv()

PLANT_ID_API_KEY = os.getenv("PLANT_ID_API_KEY")
PLANT_ID_URL = os.getenv("PLANT_ID_URL", "https://plant.id/api/v3/identification")
PLANT_ID_AUTH_MODE = os.getenv("PLANT_ID_AUTH_MODE", "body")
PLANT_ID_DETAILS = os.getenv(
    "PLANT_ID_DETAILS",
    "common_names,description_all,watering,best_watering,best_light_condition,propagation_methods",
)
PLANT_ID_LANGUAGE = os.getenv("PLANT_ID_LANGUAGE", "id")
REDIS_URL = os.getenv("REDIS_URL")

logger = logging.getLogger("orchestrator")
logging.basicConfig(level=logging.INFO)

app = FastAPI()


class SimpleCache:
    """In-memory TTL cache fallback when Redis not configured."""

    def __init__(self):
        self._store: Dict[str, Any] = {}

    async def get(self, key: str) -> Optional[Any]:
        v = self._store.get(key)
        if not v:
            return None
        expiry, val = v
        if time.time() > expiry:
            self._store.pop(key, None)
            return None
        return val

    async def set(self, key: str, value: Any, ttl: int = 24 * 3600):
        self._store[key] = (time.time() + ttl, value)


cache = SimpleCache()
app.state.metrics = {"requests": 0, "successes": 0, "failures": 0}


def _make_cache_key_for_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


async def _process_and_cache(cache_key: str, payload: dict) -> dict:
    """Check cache by key, call Plant.id with payload, normalize and cache result."""
    cached = await cache.get(cache_key)
    if cached is not None:
        app.state.metrics["successes"] += 1
        return cached

    resp = await _call_plant_id(payload)
    normalized = _normalize_plant_id_response(resp)
    await cache.set(cache_key, normalized)
    app.state.metrics["successes"] += 1
    return normalized


async def _call_plant_id(payload: dict, timeout: int = 20) -> dict:
    headers = {"Content-Type": "application/json"}
    if PLANT_ID_AUTH_MODE != "body" and PLANT_ID_API_KEY:
        headers["Api-Key"] = PLANT_ID_API_KEY
    
    attempt = 0
    backoff = 0.5
    last_exc: Optional[Exception] = None
    async with httpx.AsyncClient(timeout=timeout) as client:
        while attempt < 4:
            try:
                final_payload = payload
                if PLANT_ID_AUTH_MODE == "body" and PLANT_ID_API_KEY:
                    final_payload = {**payload, "api_key": PLANT_ID_API_KEY}

                r = await client.post(
                    PLANT_ID_URL,
                    params={"details": PLANT_ID_DETAILS, "language": PLANT_ID_LANGUAGE},
                    json=final_payload,
                    headers=headers,
                )
                r.raise_for_status()
                return r.json()
            except httpx.RequestError as e:
                last_exc = e
                attempt += 1
                logger.warning("Plant.id request failed (attempt %d): %r", attempt, e)
                await asyncio.sleep(backoff)
                backoff *= 2
            except httpx.HTTPStatusError as e:
                status = e.response.status_code if e.response is not None else None
                if status and 500 <= status < 600:
                    last_exc = e
                    attempt += 1
                    logger.warning("Plant.id returned %d (attempt %d): %r", status, attempt, e)
                    await asyncio.sleep(backoff)
                    backoff *= 2
                    continue
                raise HTTPException(status_code=502, detail=f"Upstream Plant.id error: {e}")
    raise HTTPException(status_code=502, detail=f"Upstream Plant.id error: {last_exc}")


class RedisCache:
    """Simple Redis-backed cache wrapper storing JSON-serialized values."""

    def __init__(self, redis_client, default_ttl: int = 24 * 3600):
        self._r = redis_client
        self._ttl = default_ttl

    async def get(self, key: str) -> Optional[Any]:
        v = await self._r.get(key)
        if v is None:
            return None
        try:
            if isinstance(v, bytes):
                v = v.decode("utf-8")
            return json.loads(v)
        except Exception:
            return None

    async def set(self, key: str, value: Any, ttl: int | None = None):
        ttl_val = ttl or self._ttl
        await self._r.set(key, json.dumps(value), ex=ttl_val)


@app.on_event("startup")
async def _maybe_init_redis_cache():
    global cache
    if not REDIS_URL:
        return
    if aioredis is None:
        logger.warning("REDIS_URL is set but redis.asyncio is not available; using SimpleCache")
        return
    try:
        r = aioredis.from_url(REDIS_URL)
        await r.ping()
        cache = RedisCache(r)
        logger.info("Using Redis cache at %s", REDIS_URL)
    except Exception as e:
        logger.warning("Failed to initialize Redis at %s: %s. Falling back to SimpleCache", REDIS_URL, e)


@app.get("/health")
async def health_check():
    return {"status": "ok"}


@app.post("/identify")
async def identify(request: Request, image: UploadFile | None = File(None), check_health: bool = False):
    """Identify endpoint for the app orchestrator."""
    app.state.metrics["requests"] += 1

    try:
        if image is not None:
            form = await request.form()
            lat = form.get('latitude')
            lon = form.get('longitude')
            content = await image.read()
            if not content:
                raise HTTPException(status_code=400, detail="Empty file uploaded")

            cache_key = _make_cache_key_for_bytes(content) + f"_h{check_health}_v2"
            b64 = base64.b64encode(content).decode("ascii")
            payload: dict = {"images": [b64]}

            if check_health:
                payload["health"] = "all"
                payload["similar_images"] = True

            try:
                if lat is not None:
                    payload['latitude'] = float(str(lat))
            except (ValueError, TypeError):
                pass
            try:
                if lon is not None:
                    payload['longitude'] = float(str(lon))
            except (ValueError, TypeError):
                pass
            normalized = await _process_and_cache(cache_key, payload)
            return JSONResponse(content=normalized)

        body = await request.json()
        image_url = body.get("image_url")
        if not image_url:
            raise HTTPException(status_code=400, detail="Provide `image` file or `image_url` in JSON body")

        cache_key = hashlib.sha256(image_url.encode("utf-8")).hexdigest() + f"_h{check_health}_v2"
        payload = {"image_url": image_url}
        if check_health:
            payload["health"] = "all"
            payload["similar_images"] = True

        normalized = await _process_and_cache(cache_key, payload)
        return JSONResponse(content=normalized)

    except HTTPException:
        app.state.metrics["failures"] += 1
        raise
    except Exception as e:
        app.state.metrics["failures"] += 1
        logger.exception("Identify failed: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


def _extract_detail_text_and_citation(v: Any) -> Dict[str, Optional[str]]:
    """Helper to extract text and citation from various Plant.id detail formats."""
    if v is None:
        return {"text": None, "citation": None}
    if isinstance(v, str):
        return {"text": v, "citation": None}
    if isinstance(v, list):
        return {"text": ", ".join(str(e) for e in v), "citation": None}
    if isinstance(v, dict):
        text = v.get("value") or v.get("text") or v.get("description")
        citation = v.get("citation")
        if text:
            return {"text": str(text), "citation": str(citation) if citation else None}
        return {"text": None, "citation": str(citation) if citation else None}
    return {"text": str(v), "citation": None}


def _extract_suggestions(resp: dict) -> list:
    """Extract suggestions list from response."""
    suggestions = []
    if isinstance(resp, dict):
        result_obj = resp.get("result") or {}
        if isinstance(result_obj, dict):
            classification = result_obj.get("classification")
            if isinstance(classification, dict):
                s = classification.get("suggestions")
                if isinstance(s, list):
                    suggestions = s
        if not suggestions:
            s2 = resp.get("suggestions")
            if isinstance(s2, list):
                suggestions = s2
    return suggestions


def _extract_common_name(top: dict) -> Optional[str]:
    """Extract common name from top suggestion."""
    common = None
    if top.get("plant_name"):
        common = top.get("plant_name")
    elif top.get("common_names"):
        cn = top.get("common_names")
        if isinstance(cn, list) and len(cn) > 0:
            common = str(cn[0])
        else:
            common = str(cn)

    if not common:
        details = top.get("details") or {}
        if isinstance(details, dict) and details.get("common_names"):
            cn2 = details.get("common_names")
            if isinstance(cn2, list) and len(cn2) > 0:
                common = str(cn2[0])
            else:
                common = str(cn2)
    return common


def _extract_confidence(top: dict, resp: dict) -> Optional[float]:
    """Extract confidence/probability."""
    conf = None
    for k in ("probability", "prob", "confidence"):
        v = top.get(k)
        if isinstance(v, (int, float)):
            conf = float(v)
            break

    if conf is None and isinstance(resp.get("result"), dict):
        maybe = resp["result"].get("classification")
        if isinstance(maybe, dict):
            first = maybe.get("suggestions")
            if isinstance(first, list) and len(first) > 0 and isinstance(first[0], dict):
                for k in ("probability", "prob", "confidence"):
                    v = first[0].get(k)
                    if isinstance(v, (int, float)):
                        conf = float(v)
                        break
    return conf


def _extract_care_info(details: dict) -> dict:
    """Extract care information (watering, light)."""
    care = {}

    # Watering
    watering_raw = details.get("watering")
    best_watering = _extract_detail_text_and_citation(details.get("best_watering"))
    watering_text = None
    watering_citation = best_watering["citation"]

    if isinstance(watering_raw, dict):
        min_val = watering_raw.get("min")
        max_val = watering_raw.get("max")
        if min_val is not None or max_val is not None:
            if min_val is not None and max_val is not None:
                watering_text = f"Kelembaban ideal: {min_val} — {max_val}"
            elif min_val is not None:
                watering_text = f"Kelembaban minimal: {min_val}"
            else:
                watering_text = f"Kelembaban hingga: {max_val}"

            if watering_raw.get("citation"):
                watering_citation = str(watering_raw.get("citation"))

    if not watering_text and best_watering["text"]:
        watering_text = best_watering["text"].strip()
        watering_citation = best_watering["citation"]

    if watering_text:
        care["watering"] = {"text": watering_text, "citation": watering_citation}

    # Light
    light_raw = details.get("best_light_condition") or details.get("best_light")
    light_info = _extract_detail_text_and_citation(light_raw)
    if light_info["text"]:
        care["light"] = {"text": light_info["text"].strip(), "citation": light_info["citation"]}

    return care


def _extract_health_assessment(resp: dict) -> Optional[dict]:
    """Extract health assessment."""
    result_obj = resp.get("result")
    if not isinstance(result_obj, dict):
        return None

    if "is_healthy" not in result_obj:
        return None

    health = {"is_healthy": True, "probability": 1.0, "diseases": []}
    is_healthy_obj = result_obj.get("is_healthy")
    if isinstance(is_healthy_obj, dict):
        prob = is_healthy_obj.get("probability")
        if isinstance(prob, (int, float)):
            health["probability"] = float(prob)
            health["is_healthy"] = float(prob) >= 0.5

    disease_obj = result_obj.get("disease")
    if isinstance(disease_obj, dict):
        suggestions = disease_obj.get("suggestions")
        if isinstance(suggestions, list):
            health["diseases"] = [
                {
                    "name": d.get("name"),
                    "probability": d.get("probability"),
                    "similar_images": [
                        {
                            "url": img.get("url"),
                            "url_small": img.get("url_small")
                        }
                        for img in d.get("similar_images", [])
                        if isinstance(img, dict)
                    ]
                }
                for d in suggestions if isinstance(d, dict)
            ]
    return health


def _normalize_plant_id_response(resp: dict) -> dict:
    """Normalize plant.id response to our minimal schema."""
    out: Dict[str, Any] = {"provider": "plant.id", "raw_response": resp}
    try:
        suggestions = _extract_suggestions(resp)
        top = suggestions[0] if suggestions else None

        if top and isinstance(top, dict):
            common = _extract_common_name(top)
            sci = top.get("scientific_name") or top.get("name") or top.get("species")
            conf = _extract_confidence(top, resp)

            details = top.get("details") or {}
            care = _extract_care_info(details)

            desc_raw = details.get("description_all") or details.get("description") or details.get("description_gpt")
            description = _extract_detail_text_and_citation(desc_raw)["text"]

            health = _extract_health_assessment(resp)

            out.update({
                "id": str(top.get("id") or top.get("species_id") or ""),
                "common_name": common,
                "scientific_name": str(sci) if sci is not None else None,
                "confidence": conf,
                "care": care,
                "description": description,
                "health_assessment": health
            })
    except Exception:
        logger.warning("Failed to normalize Plant.id response", exc_info=True)
    return out


# ==================== SPRINT 3: GUIDE ENDPOINTS ====================

@app.get("/guides/plant/{plant_id}")
async def get_plant_guide(plant_id: str):
    """
    Return detailed treatment guide for a plant
    For now, we'll return enhanced care info from Plant.id
    In production, this would fetch from our own database
    """
    return {
        "plant_id": plant_id,
        "title": "Panduan Lengkap Perawatan Tanaman",
        "steps": [
            {
                "step": 1,
                "title": "Penempatan & Pencahayaan",
                "description": "Tempatkan tanaman di area dengan pencahayaan tidak langsung yang cukup untuk pertumbuhan optimal.",
                "duration_minutes": 10,
                "materials": [],
                "image_url": None,
                "tips": "Hindari sinar matahari langsung pada siang hari yang dapat membakar daun"
            },
            {
                "step": 2,
                "title": "Penyiraman Rutin",
                "description": "Siram tanaman ketika permukaan tanah terasa kering sekitar 2-3 cm dari atas.",
                "duration_minutes": 5,
                "materials": ["Air bersih", "Penyiram tanaman"],
                "image_url": None,
                "tips": "Gunakan air yang sudah diendapkan semalaman untuk menghilangkan klorin"
            },
            {
                "step": 3,
                "title": "Pemupukan Berkala",
                "description": "Berikan pupuk organik setiap 2-3 minggu sekali selama musim tanam.",
                "duration_minutes": 15,
                "materials": ["Pupuk organik", "Sarung tangan", "Alat pengaduk"],
                "image_url": None,
                "tips": "Hindari pemupukan berlebihan yang dapat menyebabkan akar terbakar"
            },
            {
                "step": 4,
                "title": "Pemangkasan & Perawatan",
                "description": "Pangkas daun dan ranting yang mati atau rusak untuk mempertahankan bentuk dan kesehatan tanaman.",
                "duration_minutes": 20,
                "materials": ["Gunting tanaman steril", "Kain lap"],
                "image_url": None,
                "tips": "Gunakan gunting yang tajam dan steril untuk mencegah infeksi"
            }
        ],
        "schedule": {
            "watering": "setiap 3-4 hari",
            "fertilizing": "2 minggu sekali",
            "pruning": "1 bulan sekali",
            "pest_check": "mingguan"
        },
        "total_steps": 4,
        "estimated_total_time": 50
    }


@app.post("/guides/progress")
async def save_guide_progress(request: Request):
    """
    Save user progress in treatment guides
    Expects JSON body: {"guide_id": "123", "user_id": "abc", "current_step": 1, "completed_steps": [1], "is_completed": false}
    """
    try:
        data = await request.json()
        required_fields = ["guide_id", "user_id", "current_step"]
        for field in required_fields:
            if field not in data:
                raise HTTPException(status_code=400, detail=f"Missing field: {field}")
        
        return {
            "status": "success", 
            "message": "Progress saved",
            "data": {
                **data,
                "saved_at": time.time(),
                "id": f"progress_{int(time.time())}"
            }
        }
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/guides/disease/{disease_name}")
async def get_disease_guide(disease_name: str):
    """
    Return treatment guide for specific plant disease
    """
    return {
        "disease_name": disease_name,
        "title": f"Panduan Penanganan {disease_name}",
        "description": f"Panduan lengkap untuk mengatasi penyakit {disease_name} pada tanaman",
        "steps": [
            {
                "step": 1,
                "title": "Identifikasi Gejala",
                "description": "Kenali gejala penyakit secara tepat sebelum melakukan penanganan.",
                "duration_minutes": 10,
                "materials": ["Kaca pembesar", "Notebook"],
                "tips": "Ambil foto gejala untuk referensi"
            },
            {
                "step": 2,
                "title": "Isolasi Tanaman",
                "description": "Pisahkan tanaman yang terinfeksi untuk mencegah penyebaran.",
                "duration_minutes": 15,
                "materials": ["Pot baru", "Media tanam segar"],
                "tips": "Cuci tangan setelah menangani tanaman sakit"
            }
        ],
        "preventive_measures": [
            "Jaga kebersihan area tanam",
            "Hindari penyiraman berlebihan",
            "Berikan sirkulasi udara yang cukup"
        ],
        "recommended_treatments": [
            "Fungisida organik untuk jamur",
            "Insektisda alami untuk hama"
        ]
    }


@app.get("/guides/health")
async def guides_health_check():
    return {"status": "healthy", "service": "guide_service"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8001, reload=True)