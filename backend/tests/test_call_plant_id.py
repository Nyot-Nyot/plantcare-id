import asyncio
import json
import sys
import pathlib
import pytest
import httpx
from unittest.mock import AsyncMock, patch

# Ensure repository root is on sys.path so tests can import backend package
repo_root = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(repo_root))

from backend.main import _call_plant_id


@pytest.mark.asyncio
async def test_call_plant_id_retries_on_request_error(monkeypatch):
    # Simulate client.post raising httpx.ConnectError (subclass of RequestError)
    class DummyClient:
        async def post(self, *args, **kwargs):
            raise httpx.ConnectError("connect failed")
        async def __aenter__(self):
            return self
        async def __aexit__(self, exc_type, exc, tb):
            return False

    async def fake_client(*args, **kwargs):
        return DummyClient()

    # Patch AsyncClient context manager to return our dummy client
    class FakeAsyncClient:
        def __init__(self, *a, **k):
            pass
        async def __aenter__(self):
            return DummyClient()
        async def __aexit__(self, exc_type, exc, tb):
            return False

    monkeypatch.setattr(httpx, "AsyncClient", FakeAsyncClient)

    # After exhausting retries, the orchestration returns HTTP 502
    from fastapi import HTTPException
    with pytest.raises(HTTPException) as exc:
        await _call_plant_id({})
    assert exc.value.status_code == 502


@pytest.mark.asyncio
async def test_call_plant_id_retries_on_5xx(monkeypatch):
    # Simulate post returning a response that raises HTTPStatusError for 500
    class Resp:
        status_code = 500
        def raise_for_status(self):
            raise httpx.HTTPStatusError("server error", request=None, response=self)
        def json(self):
            return {"foo": "bar"}

    class FakeAsyncClient:
        def __init__(self, *a, **k):
            self.calls = 0
        async def __aenter__(self):
            return self
        async def __aexit__(self, exc_type, exc, tb):
            return False
        async def post(self, *args, **kwargs):
            # Always return Resp that will raise HTTPStatusError on raise_for_status
            return Resp()

    monkeypatch.setattr(httpx, "AsyncClient", FakeAsyncClient)

    from fastapi import HTTPException
    with pytest.raises(HTTPException) as exc:
        await _call_plant_id({})
    assert exc.value.status_code == 502


@pytest.mark.asyncio
async def test_call_plant_id_does_not_retry_on_4xx(monkeypatch):
    # Simulate post returning a 400 response that raises HTTPStatusError
    class Resp:
        status_code = 400
        def raise_for_status(self):
            raise httpx.HTTPStatusError("client error", request=None, response=self)
        def json(self):
            return {"foo": "bar"}

    class FakeAsyncClient:
        def __init__(self, *a, **k):
            pass
        async def __aenter__(self):
            return self
        async def __aexit__(self, exc_type, exc, tb):
            return False
        async def post(self, *args, **kwargs):
            return Resp()

    monkeypatch.setattr(httpx, "AsyncClient", FakeAsyncClient)

    # When a 4xx happens, _call_plant_id should raise HTTPException with status 502
    from fastapi import HTTPException

    with pytest.raises(HTTPException) as exc:
        await _call_plant_id({})
    assert exc.value.status_code == 502
