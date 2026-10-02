from fastapi.testclient import TestClient

from app.main import app


def test_predict_endpoint_success() -> None:
    """
    Test the /predict endpoint with valid input to ensure it returns HTTP 200
    and the correct JSON schema (is_toxic: bool, toxicity_probability: float).
    """
    # Using 'with' is mandatory to trigger FastAPI lifespan events (model loading)
    with TestClient(app) as client:
        payload = {"text": "You are an absolute idiot"}
        response = client.post("/predict", json=payload)

        # Check HTTP status
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"

        # Parse JSON response
        data = response.json()

        # Check response schema and data types
        assert "is_toxic" in data, "Key 'is_toxic' missing in response"
        assert "toxicity_probability" in data, "Key 'toxicity_probability' missing"

        assert isinstance(data["is_toxic"], bool), "'is_toxic' should be a boolean"
        assert isinstance(data["toxicity_probability"], float), (
            "'toxicity_probability' should be a float"
        )


def test_health_endpoint() -> None:
    """
    Test the /health endpoint to ensure the API is up and running.
    """
    with TestClient(app) as client:
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["model_loaded"] is True
