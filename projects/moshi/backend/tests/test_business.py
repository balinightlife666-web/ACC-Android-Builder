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


def upload_image(client: TestClient, auth: dict, payload: bytes = b"moshi-catalog-image") -> str:
    init = client.post(
        "/v1/uploads",
        headers=auth["headers"],
        json={
            "kind": "image",
            "file_name": "catalog.png",
            "content_type": "image/png",
            "size_bytes": len(payload),
        },
    )
    assert init.status_code == 201, init.text
    ticket = init.json()
    uploaded = client.put(
        ticket["upload_path"],
        headers={**auth["headers"], "Content-Type": "image/png"},
        content=payload,
    )
    assert uploaded.status_code == 200, uploaded.text
    return ticket["id"]


def test_business_profile_catalog_and_customer_view() -> None:
    with TestClient(app) as client:
        seller = register(client, "seller")
        buyer = register(client, "buyer")

        disabled = client.put(
            "/v1/business/me/profile",
            headers=seller["headers"],
            json={"business_name": "Seller Shop"},
        )
        assert disabled.status_code == 409

        enabled = client.patch(
            "/v1/me",
            headers=seller["headers"],
            json={"business_mode": True},
        )
        assert enabled.status_code == 200
        assert enabled.json()["business_mode"] is True

        profile = client.put(
            "/v1/business/me/profile",
            headers=seller["headers"],
            json={
                "business_name": "Seller Shop",
                "category": "Food",
                "description": "Fresh products",
                "address": "Bali",
                "hours": "09:00-20:00",
            },
        )
        assert profile.status_code == 200, profile.text
        assert profile.json()["business_name"] == "Seller Shop"

        image_id = upload_image(client, seller)
        product = client.post(
            "/v1/business/catalog",
            headers=seller["headers"],
            json={
                "kind": "product",
                "title": "Moshi Sauce",
                "description": "Catalog product",
                "price_amount": 125000,
                "currency": "idr",
                "availability": "available",
                "stock_qty": 12,
                "image_attachment_id": image_id,
            },
        )
        assert product.status_code == 201, product.text
        product_data = product.json()
        assert product_data["currency"] == "IDR"
        assert product_data["stock_qty"] == 12
        assert product_data["image_path"].endswith("/image")

        service = client.post(
            "/v1/business/catalog",
            headers=seller["headers"],
            json={
                "kind": "service",
                "title": "DJ Service",
                "description": "Service item",
                "price_amount": 5000000,
                "currency": "IDR",
                "availability": "available",
            },
        )
        assert service.status_code == 201, service.text
        assert service.json()["stock_qty"] is None

        bad_service = client.post(
            "/v1/business/catalog",
            headers=seller["headers"],
            json={
                "kind": "service",
                "title": "Wrong Stock Service",
                "stock_qty": 2,
            },
        )
        assert bad_service.status_code == 422

        public_profile = client.get(
            f"/v1/business/{seller['username']}/profile",
            headers=buyer["headers"],
        )
        assert public_profile.status_code == 200
        assert public_profile.json()["business_name"] == "Seller Shop"

        public_catalog = client.get(
            f"/v1/business/{seller['username']}/catalog",
            headers=buyer["headers"],
        )
        assert public_catalog.status_code == 200
        assert {item["title"] for item in public_catalog.json()} == {"Moshi Sauce", "DJ Service"}

        image = client.get(product_data["image_path"], headers=buyer["headers"])
        assert image.status_code == 200
        assert image.content == b"moshi-catalog-image"

        buyer_cannot_edit = client.patch(
            f"/v1/business/catalog/{product_data['id']}",
            headers=buyer["headers"],
            json={"price_amount": 1},
        )
        assert buyer_cannot_edit.status_code in {404, 409}

        updated = client.patch(
            f"/v1/business/catalog/{product_data['id']}",
            headers=seller["headers"],
            json={"availability": "out_of_stock", "stock_qty": 0, "price_amount": 130000},
        )
        assert updated.status_code == 200, updated.text
        assert updated.json()["availability"] == "out_of_stock"
        assert updated.json()["price_amount"] == 130000

        deleted = client.delete(
            f"/v1/business/catalog/{product_data['id']}",
            headers=seller["headers"],
        )
        assert deleted.status_code == 204

        public_after_delete = client.get(
            f"/v1/business/{seller['username']}/catalog",
            headers=buyer["headers"],
        )
        assert public_after_delete.status_code == 200
        assert [item["title"] for item in public_after_delete.json()] == ["DJ Service"]

        deleted_image = client.get(product_data["image_path"], headers=buyer["headers"])
        assert deleted_image.status_code == 404


def test_catalog_image_must_belong_to_seller() -> None:
    with TestClient(app) as client:
        seller = register(client, "sellerown")
        other = register(client, "otherown")
        assert client.patch(
            "/v1/me", headers=seller["headers"], json={"business_mode": True}
        ).status_code == 200
        assert client.put(
            "/v1/business/me/profile",
            headers=seller["headers"],
            json={"business_name": "Owner Shop"},
        ).status_code == 200

        foreign_image = upload_image(client, other, b"foreign-image")
        response = client.post(
            "/v1/business/catalog",
            headers=seller["headers"],
            json={
                "kind": "product",
                "title": "Should Fail",
                "image_attachment_id": foreign_image,
            },
        )
        assert response.status_code == 404
