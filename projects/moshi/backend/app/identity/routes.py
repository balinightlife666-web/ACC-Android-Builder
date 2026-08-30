from __future__ import annotations

from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import (
    create_access_token,
    hash_password,
    hash_refresh_token,
    new_refresh_token,
    verify_password,
)
from app.identity.deps import get_current_user, get_db
from app.identity.models import DeviceSession, User
from app.identity.schemas import (
    AuthResponse,
    LoginRequest,
    LogoutRequest,
    ProfileUpdateRequest,
    RefreshRequest,
    RegisterRequest,
    UserResponse,
)
from app.push.models import PushRegistration

router = APIRouter()


def _issue_session(db: Session, user: User, device_name: str) -> AuthResponse:
    refresh_token = new_refresh_token()
    now = datetime.now(UTC)
    session = DeviceSession(
        user_id=user.id,
        device_name=device_name,
        refresh_token_hash=hash_refresh_token(refresh_token),
        expires_at=now + timedelta(days=settings.refresh_token_days),
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    access_token, expires_in = create_access_token(user_id=user.id, session_id=session.id)
    return AuthResponse(
        user=user,
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=expires_in,
    )


def _drop_push_registration(db: Session, session_id: str) -> None:
    registration = db.scalar(
        select(PushRegistration).where(PushRegistration.session_id == session_id)
    )
    if registration is not None:
        db.delete(registration)


@router.post("/auth/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Session = Depends(get_db)) -> AuthResponse:
    existing = db.scalar(select(User).where(User.username == payload.username))
    if existing is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="username already taken")

    user = User(
        username=payload.username,
        display_name=payload.display_name.strip(),
        password_hash=hash_password(payload.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return _issue_session(db, user, payload.device_name)


@router.post("/auth/login", response_model=AuthResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> AuthResponse:
    user = db.scalar(select(User).where(User.username == payload.username))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="invalid username or password")
    return _issue_session(db, user, payload.device_name)


@router.post("/auth/refresh", response_model=AuthResponse)
def refresh(payload: RefreshRequest, db: Session = Depends(get_db)) -> AuthResponse:
    token_hash = hash_refresh_token(payload.refresh_token)
    session = db.scalar(select(DeviceSession).where(DeviceSession.refresh_token_hash == token_hash))
    now = datetime.now(UTC)
    if session is None or session.revoked_at is not None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="invalid refresh token")

    expires_at = session.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=UTC)
    if expires_at <= now:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="refresh token expired")

    user = db.get(User, session.user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="user no longer exists")

    # Rotate refresh tokens. A used token cannot be replayed. Push ownership is
    # also cleared so the newly issued session must explicitly re-register the
    # current device token.
    session.revoked_at = now
    _drop_push_registration(db, session.id)
    db.commit()
    return _issue_session(db, user, session.device_name)


@router.post("/auth/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(payload: LogoutRequest, db: Session = Depends(get_db)) -> None:
    token_hash = hash_refresh_token(payload.refresh_token)
    session = db.scalar(select(DeviceSession).where(DeviceSession.refresh_token_hash == token_hash))
    if session is not None and session.revoked_at is None:
        session.revoked_at = datetime.now(UTC)
        _drop_push_registration(db, session.id)
        db.commit()


@router.get("/me", response_model=UserResponse)
def me(user: User = Depends(get_current_user)) -> UserResponse:
    return UserResponse.model_validate(user)


@router.patch("/me", response_model=UserResponse)
def update_me(
    payload: ProfileUpdateRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> UserResponse:
    if payload.display_name is not None:
        user.display_name = payload.display_name.strip()
    if payload.business_mode is not None:
        user.business_mode = payload.business_mode
    db.add(user)
    db.commit()
    db.refresh(user)
    return UserResponse.model_validate(user)
