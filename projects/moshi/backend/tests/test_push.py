from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


def _register(client: TestClient) -> dict:
    username = f"push_{uuid4().hex[:8]}"
    response = client.post(
        "/v1/auth/register",
        json={
            "username": username,
            "display_name": "Push Test",
            "password": "push-test-password",
            "device_name": "Android Push Test",
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def test_push_token_follows_authenticated_device_session() -> None:
    token = "fcm-test-token-" + uuid4().hex * 3
    with TestClient(app) as client:
        auth = _register(client)
        headers = {"Authorization": f"Bearer {auth['access_token']}"}

        registered = client.put(
            "/v1/devices/push",
            headers=headers,
            json={"provider": "fcm", "platform": "android", "token": token},
        )
        assert registered.status_code == 200, registered.text
        assert registered.json() == {
            "provider": "fcm",
            "platform": "android",
            "registered": True,
        }

        # Re-registering is idempotent for the current session.
        again = client.put(
            "/v1/devices/push",
            headers=headers,
            json={"provider": "fcm", "platform": "android", "token": token},
        )
        assert again.status_code == 200

        removed = client.delete("/v1/devices/push", headers=headers)
        assert removed.status_code == 204

        restored = client.put(
            "/v1/devices/push",
            headers=headers,
            json={"provider": "fcm", "platform": "android", "token": token},
        )
        assert restored.status_code == 200

        # Refresh rotates the device session and clears its old push ownership.
        refreshed = client.post(
            "/v1/auth/refresh", json={"refresh_token": auth["refresh_token"]}
        )
        assert refreshed.status_code == 200, refreshed.text
        rotated = refreshed.json()
        rotated_headers = {"Authorization": f"Bearer {rotated['access_token']}"}
        moved = client.put(
            "/v1/devices/push",
            headers=rotated_headers,
            json={"provider": "fcm", "platform": "android", "token": token},
        )
        assert moved.status_code == 200, moved.text


def test_push_registration_requires_authentication() -> None:
    with TestClient(app) as client:
        response = client.put(
            "/v1/devices/push",
            json={
                "provider": "fcm",
                "platform": "android",
                "token": "fcm-test-token-" + uuid4().hex * 3,
            },
        )
        assert response.status_code == 401
