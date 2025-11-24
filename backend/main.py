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
            try:
                del self._store[key]
            except KeyError:
                pass
            return None
        return val

    async def set(self, key: str, value: Any, ttl: int = 24 * 3600):
        self._store[key] = (time.time() + ttl, value)


# Initialize cache (Redis optional). We keep a simple optional driver switch so
# if REDIS_URL is provided we will attempt to use redis.asyncio; otherwise use
# the SimpleCache above.
cache = SimpleCache()

# Basic in-memory metrics
app.state.metrics = {"requests": 0, "successes": 0, "failures": 0}


def _make_cache_key_for_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


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
                r.raise_for_status()
                return r.json()
            except Exception as e:
                last_exc = e
                attempt += 1
                logger.warning("Plant.id request failed (attempt %d): %s", attempt, e)
                await asyncio.sleep(backoff)
                backoff *= 2
    raise HTTPException(status_code=502, detail=f"Upstream Plant.id error: {last_exc}")


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
            cached = await cache.get(cache_key)
            if cached is not None:
                app.state.metrics["successes"] += 1
                return JSONResponse(content=cached)

            # Prepare base64 payload for plant.id (body-based API)
            b64 = base64.b64encode(content).decode("ascii")
            payload = {"images": [b64]}
            # Call plant.id
            resp = await _call_plant_id(payload)
            # Minimal normalization: take top suggestion if present
            normalized = _normalize_plant_id_response(resp)
            await cache.set(cache_key, normalized)
            app.state.metrics["successes"] += 1
            return JSONResponse(content=normalized)

        # Otherwise expect JSON body with image_url
        body = await request.json()
        image_url = body.get("image_url")
        if not image_url:
            raise HTTPException(status_code=400, detail="Provide `image` file or `image_url` in JSON body")
        cache_key = hashlib.sha256(image_url.encode("utf-8")).hexdigest()
        cached = await cache.get(cache_key)
        if cached is not None:
            app.state.metrics["successes"] += 1
            return JSONResponse(content=cached)

        payload = {"image_url": image_url}
        resp = await _call_plant_id(payload)
        normalized = _normalize_plant_id_response(resp)
        await cache.set(cache_key, normalized)
        app.state.metrics["successes"] += 1
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
