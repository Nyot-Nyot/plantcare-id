import base64
import json
import sys
import pathlib
from unittest.mock import AsyncMock, patch

# Ensure repository root is on sys.path so tests can import backend package
repo_root = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(repo_root))

from fastapi.testclient import TestClient

from backend.main import app

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


@patch("backend.main._call_plant_id")
def test_identify_with_image_file(mock_call):
    # Mock the upstream call to plant.id
    mock_call.return_value = {"suggestions": [{"id": "123", "scientific_name": "Ficus lyrata", "plant_name": "Fiddle Leaf Fig", "probability": 0.92}]}

    # create a small fake image
    img = base64.b64decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII="
    )

    files = {"image": ("img.png", img, "image/png")}
    r = client.post("/identify", files=files)
    assert r.status_code == 200
    body = r.json()
    assert body["provider"] == "plant.id"
    assert body["scientific_name"] == "Ficus lyrata"


@patch("backend.main._call_plant_id")
def test_identify_with_image_url(mock_call):
    mock_call.return_value = {"suggestions": [{"id": "321", "scientific_name": "Monstera deliciosa", "plant_name": "Swiss Cheese Plant", "probability": 0.88}]}

    payload = {"image_url": "https://example.com/plant.jpg"}
    r = client.post("/identify", json=payload)
    assert r.status_code == 200
    body = r.json()
    assert body["provider"] == "plant.id"
    assert body["scientific_name"] == "Monstera deliciosa"
