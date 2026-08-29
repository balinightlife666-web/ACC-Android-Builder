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


def setup_business(client: TestClient, seller: dict) -> dict:
    assert client.patch("/v1/me", headers=seller["headers"], json={"business_mode": True}).status_code == 200
    assert client.put(
        "/v1/business/me/profile",
        headers=seller["headers"],
        json={"business_name": "Ops Seller", "category": "Retail"},
    ).status_code == 200
    item = client.post(
        "/v1/business/catalog",
        headers=seller["headers"],
        json={
            "kind": "product",
            "title": "Ops Product",
            "description": "Test",
            "price_amount": 50000,
            "currency": "IDR",
            "availability": "available",
            "stock_qty": 5,
        },
    )
    assert item.status_code == 201, item.text
    return item.json()


def create_order(client: TestClient, seller: dict, buyer: dict, product: dict, quantity: int = 2) -> dict:
    direct = client.post(
        "/v1/conversations/direct",
        headers=seller["headers"],
        json={"username": buyer["username"]},
    )
    assert direct.status_code == 200, direct.text
    conversation_id = direct.json()["id"]
    shared = client.post(
        f"/v1/conversations/{conversation_id}/catalog-cards",
        headers=seller["headers"],
        json={"client_message_id": f"share-{uuid4()}", "catalog_item_id": product["id"]},
    )
    assert shared.status_code == 201, shared.text
    ordered = client.post(
        f"/v1/conversations/{conversation_id}/catalog-cards/{shared.json()['id']}/order",
        headers=buyer["headers"],
        json={"client_message_id": f"order-{uuid4()}", "quantity": quantity},
    )
    assert ordered.status_code == 201, ordered.text
    return ordered.json()


def test_order_status_stock_and_permissions() -> None:
    with TestClient(app) as client:
        seller = register(client, "ops_seller")
        buyer = register(client, "ops_buyer")
        stranger = register(client, "ops_stranger")
        product = setup_business(client, seller)
        action = create_order(client, seller, buyer, product, quantity=2)
        order_id = action["order"]["id"]

        stranger_change = client.patch(
            f"/v1/orders/{order_id}/status",
            headers=stranger["headers"],
            json={"status": "confirmed"},
        )
        assert stranger_change.status_code == 404

        invalid_buyer_confirm = client.patch(
            f"/v1/orders/{order_id}/status",
            headers=buyer["headers"],
            json={"status": "confirmed"},
        )
        assert invalid_buyer_confirm.status_code == 409

        submitted = client.patch(
            f"/v1/orders/{order_id}/status",
            headers=buyer["headers"],
            json={"status": "awaiting_confirmation"},
        )
        assert submitted.status_code == 200, submitted.text
        assert submitted.json()["status"] == "awaiting_confirmation"

        confirmed = client.patch(
            f"/v1/orders/{order_id}/status",
            headers=seller["headers"],
            json={"status": "confirmed"},
        )
        assert confirmed.status_code == 200, confirmed.text
        assert confirmed.json()["status"] == "confirmed"

        catalog = client.get("/v1/business/catalog", headers=seller["headers"])
        assert catalog.status_code == 200
        assert next(item for item in catalog.json() if item["id"] == product["id"])["stock_qty"] == 3

        same_confirm = client.patch(
            f"/v1/orders/{order_id}/status",
            headers=seller["headers"],
            json={"status": "confirmed"},
        )
        assert same_confirm.status_code == 200
        catalog = client.get("/v1/business/catalog", headers=seller["headers"])
        assert next(item for item in catalog.json() if item["id"] == product["id"])["stock_qty"] == 3

        processing = client.patch(
            f"/v1/orders/{order_id}/status",
            headers=seller["headers"],
            json={"status": "processing"},
        )
        assert processing.status_code == 200

        cancelled = client.patch(
            f"/v1/orders/{order_id}/status",
            headers=seller["headers"],
            json={"status": "cancelled"},
        )
        assert cancelled.status_code == 200
        catalog = client.get("/v1/business/catalog", headers=seller["headers"])
        assert next(item for item in catalog.json() if item["id"] == product["id"])["stock_qty"] == 5

        terminal = client.patch(
            f"/v1/orders/{order_id}/status",
            headers=seller["headers"],
            json={"status": "processing"},
        )
        assert terminal.status_code == 409


def test_quick_replies_and_private_customer_labels() -> None:
    with TestClient(app) as client:
        seller = register(client, "crm_seller")
        customer = register(client, "crm_customer")
        other_business = register(client, "crm_other")
        setup_business(client, seller)
        setup_business(client, other_business)

        quick = client.post(
            "/v1/business/quick-replies",
            headers=seller["headers"],
            json={"shortcut": "/price", "title": "Price info", "body": "Hi, here is our current price."},
        )
        assert quick.status_code == 201, quick.text
        assert quick.json()["shortcut"] == "price"

        duplicate = client.post(
            "/v1/business/quick-replies",
            headers=seller["headers"],
            json={"shortcut": "price", "title": "Duplicate", "body": "No"},
        )
        assert duplicate.status_code == 409

        label = client.post(
            "/v1/business/labels",
            headers=seller["headers"],
            json={"name": "Hot Lead"},
        )
        assert label.status_code == 201, label.text
        label_id = label.json()["id"]

        assigned = client.post(
            f"/v1/business/customers/{customer['username']}/labels/{label_id}",
            headers=seller["headers"],
        )
        assert assigned.status_code == 200, assigned.text
        assert [item["name"] for item in assigned.json()] == ["Hot Lead"]

        other_view = client.get(
            f"/v1/business/customers/{customer['username']}/labels",
            headers=other_business["headers"],
        )
        assert other_view.status_code == 200
        assert other_view.json() == []

        other_assign = client.post(
            f"/v1/business/customers/{customer['username']}/labels/{label_id}",
            headers=other_business["headers"],
        )
        assert other_assign.status_code == 404

        removed = client.delete(
            f"/v1/business/customers/{customer['username']}/labels/{label_id}",
            headers=seller["headers"],
        )
        assert removed.status_code == 200
        assert removed.json() == []
