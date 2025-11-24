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
PLANT_ID_URL = os.getenv("PLANT_ID_URL", "https://api.plant.id/v3/identify")
# Authentication mode: 'body' (api_key in JSON body) or 'header' (Authorization: Bearer)
PLANT_ID_AUTH_MODE = os.getenv("PLANT_ID_AUTH_MODE", "body")
REDIS_URL = os.getenv("REDIS_URL")

logger = logging.getLogger("orchestrator")
logging.basicConfig(level=logging.INFO)

app = FastAPI()


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
    if PLANT_ID_AUTH_MODE != "body" and PLANT_ID_API_KEY:
        headers["Authorization"] = f"Bearer {PLANT_ID_API_KEY}"
    # Simple retry/backoff. Create a single AsyncClient so connection pooling
    # and keep-alive work across retry attempts instead of recreating the
    # client on each loop iteration.
    attempt = 0
    backoff = 0.5
    last_exc: Optional[Exception] = None
    async with httpx.AsyncClient(timeout=timeout) as client:
        while attempt < 4:
                    try:
                        if PLANT_ID_AUTH_MODE == "body" and PLANT_ID_API_KEY:
                            payload_with_key = {**payload, "api_key": PLANT_ID_API_KEY}
                            r = await client.post(PLANT_ID_URL, json=payload_with_key, headers=headers)
                        else:
                            r = await client.post(PLANT_ID_URL, json=payload, headers=headers)
                        # raise_for_status will raise HTTPStatusError for 4xx/5xx
                        r.raise_for_status()
                        return r.json()
                    except httpx.RequestError as e:
                        # Network-level errors (timeouts, connection errors, DNS, etc.)
                        last_exc = e
                        attempt += 1
                        logger.warning("Plant.id request failed (attempt %d): %s", attempt, e)
                        await asyncio.sleep(backoff)
                        backoff *= 2
                    except httpx.HTTPStatusError as e:
                        # For HTTP errors, retry on 5xx, but surface 4xx immediately
                        status = e.response.status_code if e.response is not None else None
                        if status and 500 <= status < 600:
                            last_exc = e
                            attempt += 1
                            logger.warning("Plant.id returned %d (attempt %d): %s", status, attempt, e)
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
async def identify(request: Request, image: UploadFile | None = File(None)):
    """Identify endpoint for the app orchestrator.

    Accepts either multipart form upload (file field `image`) or JSON body with
    `image_url` to forward to plant.id. Returns structured JSON with at least
    id, common_name, scientific_name, confidence, provider and raw_response.
    """
    app.state.metrics["requests"] += 1

    # Prefer multipart file if provided
    try:
        if image is not None:
            content = await image.read()
            if not content:
                raise HTTPException(status_code=400, detail="Empty file uploaded")
            cache_key = _make_cache_key_for_bytes(content)

            # Prepare base64 payload for plant.id (body-based API)
            b64 = base64.b64encode(content).decode("ascii")
            payload = {"images": [b64]}
            normalized = await _process_and_cache(cache_key, payload)
            return JSONResponse(content=normalized)

        # Otherwise expect JSON body with image_url
        body = await request.json()
        image_url = body.get("image_url")
        if not image_url:
            raise HTTPException(status_code=400, detail="Provide `image` file or `image_url` in JSON body")
        cache_key = hashlib.sha256(image_url.encode("utf-8")).hexdigest()
        payload = {"image_url": image_url}
        normalized = await _process_and_cache(cache_key, payload)
        return JSONResponse(content=normalized)

    except HTTPException:
        app.state.metrics["failures"] += 1
        raise
    except Exception as e:
        app.state.metrics["failures"] += 1
        logger.exception("Identify failed: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


def _normalize_plant_id_response(resp: dict) -> dict:
    """Normalize plant.id response to our minimal schema.

    We attempt to extract the top suggestion if available. The `raw_response`
    field preserves the original payload for debugging.
    """
    out: Dict[str, Any] = {"provider": "plant.id", "raw_response": resp}
    try:
        suggestions = resp.get("suggestions") or resp.get("result") or []
        top = suggestions[0] if suggestions else None
        if top:
            out.update({
                "id": top.get("id") or top.get("species_id"),
                "common_name": top.get("plant_name") or top.get("common_names") or None,
                "scientific_name": top.get("scientific_name") or top.get("name"),
                "confidence": top.get("probability") or top.get("confidence") or None,
            })
    except Exception:
        # If normalization fails, we still return raw_response so callers can
        # inspect it.
        pass
    return out


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="127.0.0.1", port=8001, reload=True)
