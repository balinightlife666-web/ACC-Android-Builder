from __future__ import annotations

from datetime import datetime
import re

from pydantic import BaseModel, Field, field_validator

USERNAME_RE = re.compile(r"^[a-z0-9_]{3,30}$")


class RegisterRequest(BaseModel):
    username: str
    display_name: str = Field(min_length=1, max_length=80)
    password: str = Field(min_length=8, max_length=128)
    device_name: str = Field(default="Android", min_length=1, max_length=120)

    @field_validator("username")
    @classmethod
    def validate_username(cls, value: str) -> str:
        normalized = value.strip().lower()
        if not USERNAME_RE.fullmatch(normalized):
            raise ValueError("username must be 3-30 chars: lowercase letters, numbers, underscore")
        return normalized


class LoginRequest(BaseModel):
    username: str
    password: str = Field(min_length=1, max_length=128)
    device_name: str = Field(default="Android", min_length=1, max_length=120)

    @field_validator("username")
    @classmethod
    def normalize_username(cls, value: str) -> str:
        return value.strip().lower()


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=20)


class LogoutRequest(BaseModel):
    refresh_token: str = Field(min_length=20)


class UserResponse(BaseModel):
    id: str
    username: str
    display_name: str
    business_mode: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class AuthResponse(BaseModel):
    user: UserResponse
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class ProfileUpdateRequest(BaseModel):
    display_name: str | None = Field(default=None, min_length=1, max_length=80)
    business_mode: bool | None = None
