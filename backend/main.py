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

try:
    from slowapi import Limiter, _rate_limit_exceeded_handler
    from slowapi.util import get_remote_address
    from slowapi.errors import RateLimitExceeded
    SLOWAPI_AVAILABLE = True
except ImportError:  # pragma: no cover - optional dependency
    SLOWAPI_AVAILABLE = False
    Limiter = None

load_dotenv()

PLANT_ID_API_KEY = os.getenv("PLANT_ID_API_KEY")
PLANT_ID_URL = os.getenv("PLANT_ID_URL", "https://plant.id/api/v3/identification")
# Authentication mode: 'body' (api_key in JSON body) or 'header' (Api-Key header)
PLANT_ID_AUTH_MODE = os.getenv("PLANT_ID_AUTH_MODE", "body")
# Comma-separated list of details to request from Plant.id to enrich responses.
# See docs: https://plant.id/api/v3/openapi.yaml for available detail names.
# Default includes common names, more complete descriptions, watering and light info
PLANT_ID_DETAILS = os.getenv(
    "PLANT_ID_DETAILS",
    "common_names,description_all,watering,best_watering,best_light_condition,propagation_methods",
)
PLANT_ID_LANGUAGE = os.getenv("PLANT_ID_LANGUAGE", "id")
REDIS_URL = os.getenv("REDIS_URL")

logger = logging.getLogger("orchestrator")
logging.basicConfig(level=logging.INFO)

# Initialize rate limiter (100 requests per minute per user)
if SLOWAPI_AVAILABLE:
    limiter = Limiter(key_func=get_remote_address)
    app = FastAPI()
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    logger.info("Rate limiting enabled (100 req/min)")
else:
    app = FastAPI()
    logger.warning("slowapi not installed, rate limiting disabled")

# Import and include routes
try:
    from backend.routes.guides import router as guides_router
    app.include_router(guides_router)
    logger.info("Treatment guides routes registered")
except ImportError as e:
    logger.warning(f"Could not import guides routes: {e}")


class SimpleCache:
    """In-memory TTL cache fallback when Redis not configured.

    Stores {key: (expiry_ts, value)}
    """

    def __init__(self):
        self._store: Dict[str, Any] = {}

    async def get(self, key: str) -> Optional[Any]:
        v = self._store.get(key)
        if not v:
            return None
        expiry, val = v
        if time.time() > expiry:
            # Remove expired entry if present in a single atomic call.
            self._store.pop(key, None)
            return None
        return val

    async def set(self, key: str, value: Any, ttl: int = 24 * 3600):
        self._store[key] = (time.time() + ttl, value)


# Initialize cache (Redis optional). We keep a simple optional driver switch so
# if REDIS_URL is provided we will attempt to use redis.asyncio; otherwise use
# the SimpleCache above.
cache = SimpleCache()

# Placeholder for a cache backend that may be swapped to Redis at startup
# `cache` will point to either a SimpleCache or RedisCache instance.

# Basic in-memory metrics
app.state.metrics = {"requests": 0, "successes": 0, "failures": 0}


def _make_cache_key_for_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


async def _process_and_cache(cache_key: str, payload: dict) -> dict:
    """Check cache by key, call Plant.id with payload, normalize and cache result.

    Returns the normalized result (may be from cache).
    """
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
    # Use Api-Key header by default when not operating in `body` auth mode.
    # Plant.id docs expect the API key in the `Api-Key` header.
    if PLANT_ID_AUTH_MODE != "body" and PLANT_ID_API_KEY:
        headers["Api-Key"] = PLANT_ID_API_KEY
    # Simple retry/backoff. Create a single AsyncClient so connection pooling
    # and keep-alive work across retry attempts instead of recreating the
    # client on each loop iteration.
    attempt = 0
    backoff = 0.5
    last_exc: Optional[Exception] = None
    async with httpx.AsyncClient(timeout=timeout) as client:
        while attempt < 4:
                    try:
                        # Include api key in body if configured, otherwise rely on header.
                        final_payload = payload
                        if PLANT_ID_AUTH_MODE == "body" and PLANT_ID_API_KEY:
                            final_payload = {**payload, "api_key": PLANT_ID_API_KEY}

                        r = await client.post(
                            PLANT_ID_URL,
                            params={"details": PLANT_ID_DETAILS, "language": PLANT_ID_LANGUAGE},
                            json=final_payload,
                            headers=headers,
                        )
                        # raise_for_status will raise HTTPStatusError for 4xx/5xx
                        r.raise_for_status()
                        return r.json()
                    except httpx.RequestError as e:
                        # Network-level errors (timeouts, connection errors, DNS, etc.)
                        last_exc = e
                        attempt += 1
                        # Use repr(e) so the logged message includes the exception type
                        # and any internal message for easier debugging (was empty
                        # previously in some cases).
                        logger.warning("Plant.id request failed (attempt %d): %r", attempt, e)
                        await asyncio.sleep(backoff)
                        backoff *= 2
                    except httpx.HTTPStatusError as e:
                        # For HTTP errors, retry on 5xx, but surface 4xx immediately
                        status = e.response.status_code if e.response is not None else None
                        if status and 500 <= status < 600:
                            last_exc = e
                            attempt += 1
                            logger.warning("Plant.id returned %d (attempt %d): %r", status, attempt, e)
                            await asyncio.sleep(backoff)
                            backoff *= 2
                            continue
                        # Don't retry on client errors
                        raise HTTPException(status_code=502, detail=f"Upstream Plant.id error: {e}")
    raise HTTPException(status_code=502, detail=f"Upstream Plant.id error: {last_exc}")


class RedisCache:
    """Simple Redis-backed cache wrapper storing JSON-serialized values.

    Uses `SET key value EX ttl` and `GET key` semantics. Values are JSON.
    """

    def __init__(self, redis_client, default_ttl: int = 24 * 3600):
        self._r = redis_client
        self._ttl = default_ttl

    async def get(self, key: str) -> Optional[Any]:
        v = await self._r.get(key)
        if v is None:
            return None
        try:
            # redis returns bytes
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
        # quick ping to ensure reachable
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
    """Identify endpoint for the app orchestrator.

    Accepts either multipart form upload (file field `image`) or JSON body with
    `image_url` to forward to plant.id. Returns structured JSON with at least
    id, common_name, scientific_name, confidence, provider and raw_response.
    """
    app.state.metrics["requests"] += 1

    # Prefer multipart file if provided
    try:
        if image is not None:
            # If the client sent additional form fields (latitude/longitude)
            # they are available via request.form(). We read them and include
            # them in the payload forwarded to Plant.id when present.
            form = await request.form()
            lat = form.get('latitude')
            lon = form.get('longitude')
            content = await image.read()
            if not content:
                raise HTTPException(status_code=400, detail="Empty file uploaded")

            # Include check_health in cache key
            cache_key = _make_cache_key_for_bytes(content) + f"_h{check_health}_v2"

            # Prepare base64 payload for plant.id (body-based API)
            b64 = base64.b64encode(content).decode("ascii")
            payload: dict = {"images": [b64]}

            if check_health:
                payload["health"] = "all"
                payload["similar_images"] = True

            # include optional coordinates when provided
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

        # Otherwise expect JSON body with image_url
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
        # fallback: top-level suggestions may exist
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

    # 1. Try structured watering (Indonesian friendly)
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

    # 2. Fallback to English text
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

    # If 'is_healthy' is missing, we assume health wasn't requested/returned
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
    """Normalize plant.id response to our minimal schema.

    We attempt to extract the top suggestion if available. The `raw_response`
    field preserves the original payload for debugging.
    """
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

            # Description
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
        # If normalization fails, we still return raw_response so callers can
        # inspect it. Log the exception for debugging upstream response
        # format issues without surfacing an internal error to the caller.
        logger.warning("Failed to normalize Plant.id response", exc_info=True)
    return out


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="127.0.0.1", port=8001, reload=True)
