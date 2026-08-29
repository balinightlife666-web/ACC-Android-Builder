from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


def register(client: TestClient, prefix: str) -> dict:
    username = f"{prefix}_{uuid4().hex[:8]}"
    response = client.post(
        "/v1/auth/register",
        json={
            "username": username,
            "display_name": prefix.title(),
            "password": "correct-horse-battery",
            "device_name": f"{prefix} Android",
        },
    )
    assert response.status_code == 201, response.text
    data = response.json()
    data["username"] = username
    data["headers"] = {"Authorization": f"Bearer {data['access_token']}"}
    return data


def test_reply_pesan_creates_order_draft() -> None:
    with TestClient(app) as client:
        seller = register(client, "replyseller")
        buyer = register(client, "replybuyer")
        assert client.patch("/v1/me", headers=seller["headers"], json={"business_mode": True}).status_code == 200
        assert client.put(
            "/v1/business/me/profile",
            headers=seller["headers"],
            json={"business_name": "Reply Shop"},
        ).status_code == 200
        product = client.post(
            "/v1/business/catalog",
            headers=seller["headers"],
            json={
                "kind": "product",
                "title": "Reply Product",
                "price_amount": 99000,
                "currency": "IDR",
                "availability": "available",
                "stock_qty": 2,
            },
        )
        assert product.status_code == 201, product.text

        direct = client.post(
            "/v1/conversations/direct",
            headers=seller["headers"],
            json={"username": buyer["username"]},
        )
        conversation_id = direct.json()["id"]
        shared = client.post(
            f"/v1/conversations/{conversation_id}/catalog-cards",
            headers=seller["headers"],
            json={
                "client_message_id": f"share-{uuid4()}",
                "catalog_item_id": product.json()["id"],
            },
        )
        assert shared.status_code == 201, shared.text
        assert "Reply" in shared.json()["body"]

        ordered = client.post(
            f"/v1/conversations/{conversation_id}/messages",
            headers=buyer["headers"],
            json={
                "client_message_id": f"reply-order-{uuid4()}",
                "body": "PESAN",
                "reply_to_id": shared.json()["id"],
            },
        )
        assert ordered.status_code == 201, ordered.text
        payload = ordered.json()
        assert payload["order_card"] is not None
        assert payload["order_card"]["item_title"] == "Reply Product"
        assert payload["order_card"]["quantity"] == 1
        assert payload["order_card"]["total_amount"] == 99000
        assert payload["reply_to"]["id"] == shared.json()["id"]
        assert "Order draft" in payload["body"]

        drafts = client.get("/v1/orders/drafts", headers=buyer["headers"])
        assert drafts.status_code == 200
        matching = [item for item in drafts.json() if item["id"] == payload["order_card"]["order_id"]]
        assert len(matching) == 1
        assert matching[0]["status"] == "draft"
        assert matching[0]["total_amount"] == 99000
