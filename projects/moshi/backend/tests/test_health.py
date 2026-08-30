from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_meta_has_business_and_ai() -> None:
    response = client.get("/v1/meta")
    assert response.status_code == 200
    capabilities = response.json()["capabilities"]
    assert "business" in capabilities
    assert "ai-summary" in capabilities


def test_summary_contract_preserves_source_ids() -> None:
    response = client.post(
        "/v1/ai/summary",
        json={"conversation_id": "c1", "message_ids": ["m1", "m2"]},
    )
    assert response.status_code == 200
    assert response.json()["source_message_ids"] == ["m1", "m2"]
