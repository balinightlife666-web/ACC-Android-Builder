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


def direct_conversation(client: TestClient, alice: dict, bob: dict) -> dict:
    response = client.post(
        "/v1/conversations/direct",
        json={"username": bob["user"]["username"]},
        headers=auth_headers(alice),
    )
    assert response.status_code == 200, response.text
    return response.json()


def send(client: TestClient, auth: dict, conversation_id: str, body: str, reply_to_id: str | None = None) -> dict:
    payload: dict[str, str] = {"client_message_id": uuid4().hex, "body": body}
    if reply_to_id:
        payload["reply_to_id"] = reply_to_id
    response = client.post(
        f"/v1/conversations/{conversation_id}/messages",
        json=payload,
        headers=auth_headers(auth),
    )
    assert response.status_code == 201, response.text
    return response.json()


def test_direct_conversation_persistence_delivery_read_and_idempotency() -> None:
    with TestClient(app) as client:
        alice = register(client, "alice")
        bob = register(client, "bob")
        search = client.get("/v1/users/search", params={"q": bob["user"]["username"]}, headers=auth_headers(alice))
        assert search.status_code == 200
        assert search.json()[0]["username"] == bob["user"]["username"]
        conversation = direct_conversation(client, alice, bob)
        same = client.post("/v1/conversations/direct", json={"username": alice["user"]["username"]}, headers=auth_headers(bob))
        assert same.status_code == 200
        assert same.json()["id"] == conversation["id"]
        client_id = uuid4().hex
        sent = client.post(
            f"/v1/conversations/{conversation['id']}/messages",
            json={"client_message_id": client_id, "body": "Hello from MOSHI"},
            headers=auth_headers(alice),
        )
        assert sent.status_code == 201, sent.text
        message = sent.json()
        assert message["state"] == "sent"
        duplicate = client.post(
            f"/v1/conversations/{conversation['id']}/messages",
            json={"client_message_id": client_id, "body": "Hello from MOSHI"},
            headers=auth_headers(alice),
        )
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


def test_reply_edit_reaction_soft_delete_and_cumulative_read() -> None:
    with TestClient(app) as client:
        alice = register(client, "toolsalice")
        bob = register(client, "toolsbob")
        conversation = direct_conversation(client, alice, bob)
        first = send(client, alice, conversation["id"], "First message")
        second = send(client, alice, conversation["id"], "Second reply", reply_to_id=first["id"])
        assert second["reply_to"]["id"] == first["id"]
        assert second["reply_to"]["body"] == "First message"

        client.get(f"/v1/conversations/{conversation['id']}/messages", headers=auth_headers(bob))
        read = client.post(
            f"/v1/conversations/{conversation['id']}/read",
            json={"message_id": second["id"]},
            headers=auth_headers(bob),
        )
        assert read.status_code == 204
        alice_history = client.get(f"/v1/conversations/{conversation['id']}/messages", headers=auth_headers(alice)).json()
        assert [item["state"] for item in alice_history[-2:]] == ["read", "read"]

        edit = client.patch(
            f"/v1/conversations/{conversation['id']}/messages/{first['id']}",
            json={"body": "First message edited"},
            headers=auth_headers(alice),
        )
        assert edit.status_code == 200, edit.text
        assert edit.json()["body"] == "First message edited"
        assert edit.json()["edited_at"] is not None
        forbidden = client.patch(
            f"/v1/conversations/{conversation['id']}/messages/{first['id']}",
            json={"body": "Bob cannot edit this"},
            headers=auth_headers(bob),
        )
        assert forbidden.status_code == 403

        reaction = client.post(
            f"/v1/conversations/{conversation['id']}/messages/{first['id']}/reactions",
            json={"emoji": "👍"},
            headers=auth_headers(bob),
        )
        assert reaction.status_code == 200, reaction.text
        assert reaction.json()["reactions"] == [{"emoji": "👍", "count": 1, "reacted_by_me": True}]
        alice_view = client.get(f"/v1/conversations/{conversation['id']}/messages", headers=auth_headers(alice)).json()
        first_view = next(item for item in alice_view if item["id"] == first["id"])
        assert first_view["reactions"] == [{"emoji": "👍", "count": 1, "reacted_by_me": False}]
        toggle_off = client.post(
            f"/v1/conversations/{conversation['id']}/messages/{first['id']}/reactions",
            json={"emoji": "👍"},
            headers=auth_headers(bob),
        )
        assert toggle_off.json()["reactions"] == []

        deleted = client.delete(
            f"/v1/conversations/{conversation['id']}/messages/{first['id']}",
            headers=auth_headers(alice),
        )
        assert deleted.status_code == 200, deleted.text
        assert deleted.json()["is_deleted"] is True
        assert deleted.json()["body"] == ""
        history = client.get(f"/v1/conversations/{conversation['id']}/messages", headers=auth_headers(bob)).json()
        reply = next(item for item in history if item["id"] == second["id"])
        assert reply["reply_to"]["is_deleted"] is True
        assert reply["reply_to"]["body"] == ""


def test_websocket_receives_new_and_updated_message_events() -> None:
    with TestClient(app) as client:
        alice = register(client, "wsalice")
        bob = register(client, "wsbob")
        conversation = direct_conversation(client, alice, bob)
        with client.websocket_connect(f"/v1/ws?token={bob['access_token']}") as websocket:
            assert websocket.receive_json()["type"] == "ready"
            websocket.send_json({"type": "ping"})
            assert websocket.receive_json()["type"] == "pong"
            sent = send(client, alice, conversation["id"], "Realtime hello")
            event = websocket.receive_json()
            assert event["type"] == "message.created"
            assert event["message"]["body"] == "Realtime hello"
            edited = client.patch(
                f"/v1/conversations/{conversation['id']}/messages/{sent['id']}",
                json={"body": "Realtime edited"},
                headers=auth_headers(alice),
            )
            assert edited.status_code == 200
            updated = websocket.receive_json()
            assert updated["type"] == "message.updated"
            assert updated["message"]["body"] == "Realtime edited"
        delivered = client.get(f"/v1/conversations/{conversation['id']}/messages", headers=auth_headers(alice))
        assert delivered.json()[-1]["state"] == "delivered"


def test_attachment_upload_attach_download_authorization_and_delete() -> None:
    with TestClient(app) as client:
        alice = register(client, "mediaalice")
        bob = register(client, "mediabob")
        eve = register(client, "mediaeve")
        conversation = direct_conversation(client, alice, bob)
        content = b"moshi-image-test-bytes"

        init = client.post(
            "/v1/uploads",
            json={
                "kind": "image",
                "file_name": "../photo.jpg",
                "content_type": "image/jpeg",
                "size_bytes": len(content),
            },
            headers=auth_headers(alice),
        )
        assert init.status_code == 201, init.text
        upload = init.json()
        assert upload["file_name"] == "photo.jpg"
        assert upload["status"] == "pending"

        not_owner = client.put(
            upload["upload_path"],
            content=content,
            headers={**auth_headers(bob), "Content-Type": "image/jpeg"},
        )
        assert not_owner.status_code == 404

        uploaded = client.put(
            upload["upload_path"],
            content=content,
            headers={**auth_headers(alice), "Content-Type": "image/jpeg"},
        )
        assert uploaded.status_code == 200, uploaded.text
        assert uploaded.json()["status"] == "ready"

        sent = client.post(
            f"/v1/conversations/{conversation['id']}/messages",
            json={
                "client_message_id": uuid4().hex,
                "body": "",
                "attachment_ids": [upload["id"]],
            },
            headers=auth_headers(alice),
        )
        assert sent.status_code == 201, sent.text
        message = sent.json()
        assert message["body"] == ""
        assert len(message["attachments"]) == 1
        attachment = message["attachments"][0]
        assert attachment["status"] == "attached"
        assert attachment["content_type"] == "image/jpeg"

        bob_download = client.get(attachment["download_path"], headers=auth_headers(bob))
        assert bob_download.status_code == 200
        assert bob_download.content == content

        eve_download = client.get(attachment["download_path"], headers=auth_headers(eve))
        assert eve_download.status_code == 404

        reuse = client.post(
            f"/v1/conversations/{conversation['id']}/messages",
            json={
                "client_message_id": uuid4().hex,
                "body": "cannot reuse",
                "attachment_ids": [upload["id"]],
            },
            headers=auth_headers(alice),
        )
        assert reuse.status_code == 400

        deleted = client.delete(
            f"/v1/conversations/{conversation['id']}/messages/{message['id']}",
            headers=auth_headers(alice),
        )
        assert deleted.status_code == 200
        assert deleted.json()["attachments"] == []
        after_delete = client.get(attachment["download_path"], headers=auth_headers(bob))
        assert after_delete.status_code == 404
