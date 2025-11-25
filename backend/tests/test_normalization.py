import sys
import pathlib
from unittest.mock import patch
from fastapi.testclient import TestClient

# Ensure repository root is on sys.path
repo_root = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(repo_root))

from backend.main import app, cache

client = TestClient(app)

@patch("backend.main._call_plant_id")
def test_identify_normalization_complex(mock_call):
    # Clear cache to ensure no interference
    if hasattr(cache, "_store"):
        cache._store.clear()
    # Mock a complex response from Plant.id v3
    mock_response = {
        "result": {
            "classification": {
                "suggestions": [
                    {
                        "id": "12345",
                        "name": "Ficus lyrata",
                        "probability": 0.95,
                        "details": {
                            "common_names": ["Fiddle Leaf Fig"],
                            "description": {"value": "A popular indoor plant.", "citation": "Wiki"},
                            "best_watering": {"value": "Keep moist.", "citation": "GardenGuide"},
                            "best_light_condition": "Bright indirect light"
                        }
                    }
                ]
            },
            "is_healthy": {
                "probability": 0.8
            },
            "disease": {
                "suggestions": []
            }
        }
    }
    mock_call.return_value = mock_response

    payload = {"image_url": "https://example.com/plant_complex.jpg"}
    r = client.post("/identify", json=payload)
    assert r.status_code == 200
    body = r.json()

    # Check basic fields
    assert body["scientific_name"] == "Ficus lyrata"
    assert body["common_name"] == "Fiddle Leaf Fig"
    assert body["confidence"] == 0.95

    # Check normalized fields
    assert body["description"] == "A popular indoor plant."

    # Check care fields
    care = body["care"]
    assert care["watering"]["text"] == "Keep moist."
    assert care["watering"]["citation"] == "GardenGuide"
    assert care["light"]["text"] == "Bright indirect light"

    # Check health
    health = body["health_assessment"]
    assert health["is_healthy"] is True
    assert health["probability"] == 0.8
    assert health["diseases"] == []

@patch("backend.main._call_plant_id")
def test_identify_normalization_unhealthy(mock_call):
    # Mock an unhealthy response
    mock_response = {
        "result": {
            "classification": {
                "suggestions": [{"name": "Rose", "probability": 0.9}]
            },
            "is_healthy": {
                "probability": 0.2
            },
            "disease": {
                "suggestions": [
                    {"name": "Black Spot", "probability": 0.85},
                    {"name": "Powdery Mildew", "probability": 0.1}
                ]
            }
        }
    }
    mock_call.return_value = mock_response

    payload = {"image_url": "https://example.com/rose.jpg"}
    r = client.post("/identify", json=payload)
    assert r.status_code == 200
    body = r.json()

    health = body["health_assessment"]
    assert health["is_healthy"] is False
    assert health["probability"] == 0.2
    assert len(health["diseases"]) == 2
    assert health["diseases"][0]["name"] == "Black Spot"
