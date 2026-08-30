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


def test_group_roles_members_and_messages() -> None:
    with TestClient(app) as client:
        owner = register(client, "owner")
        moderator = register(client, "moderator")
        member = register(client, "member")
        recruit = register(client, "recruit")
        outsider = register(client, "outsider")

        created = client.post(
            "/v1/groups",
            headers=owner["headers"],
            json={
                "title": "MOSHI Crew",
                "description": "Group chat integration test",
                "usernames": [moderator["username"], member["username"]],
            },
        )
        assert created.status_code == 201, created.text
        group = created.json()
        group_id = group["id"]
        assert group["kind"] == "group"
        assert group["group"]["title"] == "MOSHI Crew"
        assert group["group"]["my_role"] == "admin"
        assert group["group"]["member_count"] == 3

        outsider_view = client.get(f"/v1/groups/{group_id}/members", headers=outsider["headers"])
        assert outsider_view.status_code == 404

        member_list = client.get(f"/v1/groups/{group_id}/members", headers=member["headers"])
        assert member_list.status_code == 200
        assert len(member_list.json()) == 3

        member_add = client.post(
            f"/v1/groups/{group_id}/members",
            headers=member["headers"],
            json={"username": recruit["username"]},
        )
        assert member_add.status_code == 403

        promoted = client.patch(
            f"/v1/groups/{group_id}/members/{moderator['user']['id']}/role",
            headers=owner["headers"],
            json={"role": "moderator"},
        )
        assert promoted.status_code == 200, promoted.text
        assert promoted.json()["role"] == "moderator"

        mod_add = client.post(
            f"/v1/groups/{group_id}/members",
            headers=moderator["headers"],
            json={"username": recruit["username"]},
        )
        assert mod_add.status_code == 201, mod_add.text
        assert mod_add.json()["role"] == "member"

        mod_promote = client.patch(
            f"/v1/groups/{group_id}/members/{recruit['user']['id']}/role",
            headers=moderator["headers"],
            json={"role": "moderator"},
        )
        assert mod_promote.status_code == 403

        sent = client.post(
            f"/v1/conversations/{group_id}/messages",
            headers=member["headers"],
            json={"client_message_id": uuid4().hex, "body": "Hello MOSHI group"},
        )
        assert sent.status_code == 201, sent.text
        assert sent.json()["body"] == "Hello MOSHI group"

        owner_messages = client.get(
            f"/v1/conversations/{group_id}/messages",
            headers=owner["headers"],
        )
        assert owner_messages.status_code == 200
        assert owner_messages.json()[-1]["body"] == "Hello MOSHI group"

        removed = client.delete(
            f"/v1/groups/{group_id}/members/{recruit['user']['id']}",
            headers=moderator["headers"],
        )
        assert removed.status_code == 204

        removed_cannot_chat = client.post(
            f"/v1/conversations/{group_id}/messages",
            headers=recruit["headers"],
            json={"client_message_id": uuid4().hex, "body": "Should fail"},
        )
        assert removed_cannot_chat.status_code == 404

        last_admin = client.patch(
            f"/v1/groups/{group_id}/members/{owner['user']['id']}/role",
            headers=owner["headers"],
            json={"role": "member"},
        )
        assert last_admin.status_code == 409

        updated = client.patch(
            f"/v1/groups/{group_id}",
            headers=owner["headers"],
            json={"title": "MOSHI Core Crew"},
        )
        assert updated.status_code == 200
        assert updated.json()["group"]["title"] == "MOSHI Core Crew"
