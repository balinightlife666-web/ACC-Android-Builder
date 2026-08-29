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


def setup_seller(client: TestClient, seller: dict, image: bool = False) -> dict:
    assert client.patch(
        "/v1/me", headers=seller["headers"], json={"business_mode": True}
    ).status_code == 200
    assert client.put(
        "/v1/business/me/profile",
        headers=seller["headers"],
        json={"business_name": "MOSHI Seller", "category": "Food"},
    ).status_code == 200
    image_id = None
    if image:
        payload = b"commerce-card-image"
        init = client.post(
            "/v1/uploads",
            headers=seller["headers"],
            json={
                "kind": "image",
                "file_name": "item.png",
                "content_type": "image/png",
                "size_bytes": len(payload),
            },
        )
        assert init.status_code == 201, init.text
        ticket = init.json()
        uploaded = client.put(
            ticket["upload_path"],
            headers={**seller["headers"], "Content-Type": "image/png"},
            content=payload,
        )
        assert uploaded.status_code == 200, uploaded.text
        image_id = ticket["id"]
    product = client.post(
        "/v1/business/catalog",
        headers=seller["headers"],
        json={
            "kind": "product",
            "title": "Moshi Sauce",
            "description": "Hot sauce",
            "price_amount": 125000,
            "currency": "IDR",
            "availability": "available",
            "stock_qty": 3,
            "image_attachment_id": image_id,
        },
    )
    assert product.status_code == 201, product.text
    return product.json()


def test_catalog_card_snapshot_order_draft_and_idempotency() -> None:
    with TestClient(app) as client:
        seller = register(client, "commerce_seller")
        buyer = register(client, "commerce_buyer")
        product = setup_seller(client, seller, image=True)

        direct = client.post(
            "/v1/conversations/direct",
            headers=seller["headers"],
            json={"username": buyer["username"]},
        )
        assert direct.status_code == 200, direct.text
        conversation_id = direct.json()["id"]

        share_client_id = f"share-{uuid4()}"
        shared = client.post(
            f"/v1/conversations/{conversation_id}/catalog-cards",
            headers=seller["headers"],
            json={
                "client_message_id": share_client_id,
                "catalog_item_id": product["id"],
                "body": "Recommended for you",
            },
        )
        assert shared.status_code == 201, shared.text
        shared_message = shared.json()
        assert shared_message["catalog_card"]["title"] == "Moshi Sauce"
        assert shared_message["catalog_card"]["price_amount"] == 125000
        assert shared_message["catalog_card"]["image_path"]
        assert shared_message["order_card"] is None

        duplicate_share = client.post(
            f"/v1/conversations/{conversation_id}/catalog-cards",
            headers=seller["headers"],
            json={"client_message_id": share_client_id, "catalog_item_id": product["id"]},
        )
        assert duplicate_share.status_code == 201, duplicate_share.text
        assert duplicate_share.json()["id"] == shared_message["id"]

        updated = client.patch(
            f"/v1/business/catalog/{product['id']}",
            headers=seller["headers"],
            json={"price_amount": 130000, "stock_qty": 2},
        )
        assert updated.status_code == 200, updated.text

        buyer_history = client.get(
            f"/v1/conversations/{conversation_id}/messages",
            headers=buyer["headers"],
        )
        assert buyer_history.status_code == 200, buyer_history.text
        history_card = next(item for item in buyer_history.json() if item["id"] == shared_message["id"])["catalog_card"]
        assert history_card["price_amount"] == 125000
        assert history_card["stock_qty"] == 3

        too_many = client.post(
            f"/v1/conversations/{conversation_id}/catalog-cards/{shared_message['id']}/order",
            headers=buyer["headers"],
            json={"client_message_id": f"order-{uuid4()}", "quantity": 3},
        )
        assert too_many.status_code == 409

        order_client_id = f"order-{uuid4()}"
        ordered = client.post(
            f"/v1/conversations/{conversation_id}/catalog-cards/{shared_message['id']}/order",
            headers=buyer["headers"],
            json={"client_message_id": order_client_id, "quantity": 2, "note": "Please pack securely"},
        )
        assert ordered.status_code == 201, ordered.text
        action = ordered.json()
        assert action["order"]["status"] == "draft"
        assert action["order"]["total_amount"] == 260000
        assert action["order"]["items"][0]["unit_price_amount"] == 130000
        assert action["order"]["items"][0]["quantity"] == 2
        assert action["message"]["order_card"]["order_id"] == action["order"]["id"]
        assert action["message"]["order_card"]["total_amount"] == 260000
        assert action["message"]["reply_to"]["id"] == shared_message["id"]

        duplicate_order = client.post(
            f"/v1/conversations/{conversation_id}/catalog-cards/{shared_message['id']}/order",
            headers=buyer["headers"],
            json={"client_message_id": order_client_id, "quantity": 2},
        )
        assert duplicate_order.status_code == 201, duplicate_order.text
        assert duplicate_order.json()["order"]["id"] == action["order"]["id"]
        assert duplicate_order.json()["message"]["id"] == action["message"]["id"]

        seller_orders = client.get("/v1/orders/drafts", headers=seller["headers"])
        assert seller_orders.status_code == 200
        assert any(item["id"] == action["order"]["id"] for item in seller_orders.json())

        deleted = client.delete(
            f"/v1/business/catalog/{product['id']}",
            headers=seller["headers"],
        )
        assert deleted.status_code == 204

        historical_image = client.get(
            shared_message["catalog_card"]["image_path"],
            headers=buyer["headers"],
        )
        assert historical_image.status_code == 200
        assert historical_image.content == b"commerce-card-image"

        unavailable_order = client.post(
            f"/v1/conversations/{conversation_id}/catalog-cards/{shared_message['id']}/order",
            headers=buyer["headers"],
            json={"client_message_id": f"late-{uuid4()}", "quantity": 1},
        )
        assert unavailable_order.status_code == 409


def test_seller_cannot_order_own_card() -> None:
    with TestClient(app) as client:
        seller = register(client, "self_seller")
        buyer = register(client, "self_buyer")
        product = setup_seller(client, seller)
        direct = client.post(
            "/v1/conversations/direct",
            headers=seller["headers"],
            json={"username": buyer["username"]},
        )
        conversation_id = direct.json()["id"]
        shared = client.post(
            f"/v1/conversations/{conversation_id}/catalog-cards",
            headers=seller["headers"],
            json={"client_message_id": f"share-{uuid4()}", "catalog_item_id": product["id"]},
        )
        assert shared.status_code == 201
        response = client.post(
            f"/v1/conversations/{conversation_id}/catalog-cards/{shared.json()['id']}/order",
            headers=seller["headers"],
            json={"client_message_id": f"order-{uuid4()}", "quantity": 1},
        )
        assert response.status_code == 400
