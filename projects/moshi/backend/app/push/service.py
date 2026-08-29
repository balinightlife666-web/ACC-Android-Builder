from __future__ import annotations

import asyncio
from datetime import UTC, datetime

import google.auth
from google.auth.credentials import Credentials
from google.auth.transport.requests import Request as GoogleAuthRequest
import httpx
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.identity.models import DeviceSession
from app.push.models import PushRegistration

_FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
_credentials: Credentials | None = None


def active_push_registrations(db: Session, user_id: str) -> list[PushRegistration]:
    now = datetime.now(UTC)
    return list(
        db.scalars(
            select(PushRegistration)
            .join(DeviceSession, DeviceSession.id == PushRegistration.session_id)
            .where(
                PushRegistration.user_id == user_id,
                PushRegistration.provider == "fcm",
                DeviceSession.revoked_at.is_(None),
                DeviceSession.expires_at > now,
            )
        ).all()
    )


def _load_credentials() -> Credentials:
    global _credentials
    if _credentials is None:
        credentials, _ = google.auth.default(scopes=[_FCM_SCOPE])
        _credentials = credentials
    if not _credentials.valid:
        _credentials.refresh(GoogleAuthRequest())
    return _credentials


async def _access_token() -> str | None:
    if not settings.fcm_project_id:
        return None
    try:
        credentials = await asyncio.to_thread(_load_credentials)
        return credentials.token
    except Exception:
        # Missing/invalid cloud credentials must never break chat delivery.
        return None


async def notify_new_message(
    db: Session,
    recipient_user_id: str,
    conversation_id: str,
    message_id: str,
) -> int:
    registrations = active_push_registrations(db, recipient_user_id)
    if not registrations:
        return 0
    access_token = await _access_token()
    if not access_token or not settings.fcm_project_id:
        return 0

    endpoint = (
        f"https://fcm.googleapis.com/v1/projects/{settings.fcm_project_id}/messages:send"
    )
    headers = {"Authorization": f"Bearer {access_token}"}
    sent = 0
    stale: list[PushRegistration] = []
    async with httpx.AsyncClient(timeout=8.0) as client:
        for registration in registrations:
            payload = {
                "message": {
                    "token": registration.token,
                    "data": {
                        "type": "message.created",
                        "conversation_id": conversation_id,
                        "message_id": message_id,
                        # Keep lock-screen content private by default. The app can
                        # fetch authorized message content after the user opens it.
                        "title": "MOSHI",
                        "body": "New message",
                    },
                    "android": {"priority": "high"},
                }
            }
            try:
                response = await client.post(endpoint, headers=headers, json=payload)
            except httpx.HTTPError:
                continue
            if response.is_success:
                sent += 1
            elif response.status_code in {400, 404} and "UNREGISTERED" in response.text.upper():
                stale.append(registration)

    if stale:
        for registration in stale:
            db.delete(registration)
        db.commit()
    return sent
