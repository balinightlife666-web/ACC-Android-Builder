from __future__ import annotations

from collections.abc import Generator

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import jwt
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.core.security import decode_access_token
from app.identity.models import DeviceSession, User

bearer = HTTPBearer(auto_error=False)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _unauthorized() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="invalid or expired access token",
        headers={"WWW-Authenticate": "Bearer"},
    )


def authenticate_access_session(token: str, db: Session) -> DeviceSession:
    unauthorized = _unauthorized()
    try:
        payload = decode_access_token(token)
        user_id = str(payload["sub"])
        session_id = str(payload["sid"])
    except (jwt.InvalidTokenError, KeyError):
        raise unauthorized from None

    session = db.get(DeviceSession, session_id)
    if session is None or session.user_id != user_id or session.revoked_at is not None:
        raise unauthorized
    if db.get(User, user_id) is None:
        raise unauthorized
    return session


def authenticate_access_token(token: str, db: Session) -> User:
    session = authenticate_access_session(token, db)
    user = db.get(User, session.user_id)
    if user is None:
        raise _unauthorized()
    return user


def get_current_session(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> DeviceSession:
    if credentials is None:
        raise _unauthorized()
    return authenticate_access_session(credentials.credentials, db)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None:
        raise _unauthorized()
    return authenticate_access_token(credentials.credentials, db)
