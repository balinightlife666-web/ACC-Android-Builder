from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


def register(client: TestClient, prefix: str) -> dict:
    response = client.post(
        "/v1/auth/register",
        json={
            "username": f"{prefix}_{uuid4().hex[:8]}",
            "display_name": prefix.title(),
            "password": "correct-horse-battery",
            "device_name": "Android Voice Test",
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def headers(auth: dict) -> dict[str, str]:
    return {"Authorization": f"Bearer {auth['access_token']}"}


def test_voice_note_audio_mp4_upload_send_and_download() -> None:
    with TestClient(app) as client:
        alice = register(client, "voicealice")
        bob = register(client, "voicebob")
        conversation = client.post(
            "/v1/conversations/direct",
            json={"username": bob["user"]["username"]},
            headers=headers(alice),
        )
        assert conversation.status_code == 200, conversation.text
        conversation_id = conversation.json()["id"]

        # The attachment service validates declared type/size and authorization.
        # Media decoding belongs to device QA/player layers, not this API test.
        audio = b"moshi-aac-in-mp4-test-payload"
        init = client.post(
            "/v1/uploads",
            json={
                "kind": "file",
                "file_name": "voice-note.m4a",
                "content_type": "audio/mp4",
                "size_bytes": len(audio),
            },
            headers=headers(alice),
        )
        assert init.status_code == 201, init.text
        ticket = init.json()

        upload = client.put(
            ticket["upload_path"],
            content=audio,
            headers={**headers(alice), "Content-Type": "audio/mp4"},
        )
        assert upload.status_code == 200, upload.text
        attachment = upload.json()
        assert attachment["status"] == "ready"
        assert attachment["content_type"] == "audio/mp4"

        sent = client.post(
            f"/v1/conversations/{conversation_id}/messages",
            json={
                "client_message_id": uuid4().hex,
                "body": "",
                "attachment_ids": [attachment["id"]],
            },
            headers=headers(alice),
        )
        assert sent.status_code == 201, sent.text
        message = sent.json()
        assert message["attachments"][0]["file_name"] == "voice-note.m4a"
        assert message["attachments"][0]["content_type"] == "audio/mp4"

        downloaded = client.get(
            message["attachments"][0]["download_path"],
            headers=headers(bob),
        )
        assert downloaded.status_code == 200, downloaded.text
        assert downloaded.content == audio
        assert downloaded.headers["content-type"].startswith("audio/mp4")


def test_voice_note_rejects_unapproved_audio_type() -> None:
    with TestClient(app) as client:
        alice = register(client, "voicebad")
        response = client.post(
            "/v1/uploads",
            json={
                "kind": "file",
                "file_name": "voice.flac",
                "content_type": "audio/flac",
                "size_bytes": 10,
            },
            headers=headers(alice),
        )
        assert response.status_code == 415
