from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


def unique_username(prefix: str = "arda") -> str:
    return f"{prefix}_{uuid4().hex[:8]}"


def test_register_me_update_refresh_and_logout() -> None:
    username = unique_username()
    with TestClient(app) as client:
        register = client.post(
            "/v1/auth/register",
            json={
                "username": username,
                "display_name": "Arda",
                "password": "correct-horse-battery",
                "device_name": "Android Test",
            },
        )
        assert register.status_code == 201, register.text
        auth = register.json()
        assert auth["user"]["username"] == username
        assert auth["token_type"] == "bearer"
        assert auth["expires_in"] > 0

        headers = {"Authorization": f"Bearer {auth['access_token']}"}
        me = client.get("/v1/me", headers=headers)
        assert me.status_code == 200
        assert me.json()["display_name"] == "Arda"

        updated = client.patch(
            "/v1/me",
            headers=headers,
            json={"display_name": "Arda MOSHI", "business_mode": True},
        )
        assert updated.status_code == 200
        assert updated.json()["business_mode"] is True

        refreshed = client.post(
            "/v1/auth/refresh", json={"refresh_token": auth["refresh_token"]}
        )
        assert refreshed.status_code == 200
        rotated = refreshed.json()
        assert rotated["refresh_token"] != auth["refresh_token"]

        replay = client.post(
            "/v1/auth/refresh", json={"refresh_token": auth["refresh_token"]}
        )
        assert replay.status_code == 401

        logout = client.post(
            "/v1/auth/logout", json={"refresh_token": rotated["refresh_token"]}
        )
        assert logout.status_code == 204

        after_logout = client.get(
            "/v1/me",
            headers={"Authorization": f"Bearer {rotated['access_token']}"},
        )
        assert after_logout.status_code == 401


def test_duplicate_username_is_rejected() -> None:
    username = unique_username("dup")
    payload = {
        "username": username,
        "display_name": "One",
        "password": "very-secret-password",
        "device_name": "Android",
    }
    with TestClient(app) as client:
        assert client.post("/v1/auth/register", json=payload).status_code == 201
        duplicate = client.post("/v1/auth/register", json=payload)
        assert duplicate.status_code == 409


def test_invalid_login_is_rejected() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/v1/auth/login",
            json={
                "username": unique_username("missing"),
                "password": "wrong-password",
                "device_name": "Android",
            },
        )
        assert response.status_code == 401
