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
            "device_name": "Android Test",
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def auth_headers(auth: dict) -> dict[str, str]:
    return {"Authorization": f"Bearer {auth['access_token']}"}


def test_direct_conversation_persistence_delivery_read_and_idempotency() -> None:
    with TestClient(app) as client:
        alice = register(client, "alice")
        bob = register(client, "bob")
        search = client.get("/v1/users/search", params={"q": bob["user"]["username"]}, headers=auth_headers(alice))
        assert search.status_code == 200
        assert search.json()[0]["username"] == bob["user"]["username"]
        created = client.post("/v1/conversations/direct", json={"username": bob["user"]["username"]}, headers=auth_headers(alice))
        assert created.status_code == 200, created.text
        conversation = created.json()
        same = client.post("/v1/conversations/direct", json={"username": alice["user"]["username"]}, headers=auth_headers(bob))
        assert same.status_code == 200
        assert same.json()["id"] == conversation["id"]
        client_id = uuid4().hex
        sent = client.post(f"/v1/conversations/{conversation['id']}/messages", json={"client_message_id": client_id, "body": "Hello from MOSHI"}, headers=auth_headers(alice))
        assert sent.status_code == 201, sent.text
        message = sent.json()
        assert message["state"] == "sent"
        duplicate = client.post(f"/v1/conversations/{conversation['id']}/messages", json={"client_message_id": client_id, "body": "Hello from MOSHI"}, headers=auth_headers(alice))
        assert duplicate.status_code == 201
        assert duplicate.json()["id"] == message["id"]
        bob_messages = client.get(f"/v1/conversations/{conversation['id']}/messages", headers=auth_headers(bob))
        assert bob_messages.status_code == 200
        assert bob_messages.json()[-1]["body"] == "Hello from MOSHI"
        delivered = client.get(f"/v1/conversations/{conversation['id']}/messages", headers=auth_headers(alice))
        assert delivered.json()[-1]["state"] == "delivered"
        read = client.post(f"/v1/conversations/{conversation['id']}/read", json={"message_id": message["id"]}, headers=auth_headers(bob))
        assert read.status_code == 204
        after_read = client.get(f"/v1/conversations/{conversation['id']}/messages", headers=auth_headers(alice))
        assert after_read.json()[-1]["state"] == "read"
        bob_list = client.get("/v1/conversations", headers=auth_headers(bob))
        assert bob_list.status_code == 200
        assert bob_list.json()[0]["unread_count"] == 0


def test_websocket_receives_new_message_and_ping_pong() -> None:
    with TestClient(app) as client:
        alice = register(client, "wsalice")
        bob = register(client, "wsbob")
        conversation = client.post("/v1/conversations/direct", json={"username": bob["user"]["username"]}, headers=auth_headers(alice)).json()
        with client.websocket_connect(f"/v1/ws?token={bob['access_token']}") as websocket:
            assert websocket.receive_json()["type"] == "ready"
            websocket.send_json({"type": "ping"})
            assert websocket.receive_json()["type"] == "pong"
            sent = client.post(f"/v1/conversations/{conversation['id']}/messages", json={"client_message_id": uuid4().hex, "body": "Realtime hello"}, headers=auth_headers(alice))
            assert sent.status_code == 201
            event = websocket.receive_json()
            assert event["type"] == "message.created"
            assert event["message"]["body"] == "Realtime hello"
        delivered = client.get(f"/v1/conversations/{conversation['id']}/messages", headers=auth_headers(alice))
        assert delivered.json()[-1]["state"] == "delivered"
