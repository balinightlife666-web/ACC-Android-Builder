from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field, field_validator

from app.chat.schemas import UserPreview


class GroupCreateRequest(BaseModel):
    title: str = Field(min_length=1, max_length=120)
    description: str = Field(default="", max_length=500)
    usernames: list[str] = Field(default_factory=list, max_length=99)

    @field_validator("title", "description")
    @classmethod
    def trim_text(cls, value: str) -> str:
        return value.strip()

    @field_validator("usernames")
    @classmethod
    def normalize_usernames(cls, values: list[str]) -> list[str]:
        normalized: list[str] = []
        seen: set[str] = set()
        for value in values:
            username = value.strip().lower().lstrip("@")
            if not username or username in seen:
                continue
            seen.add(username)
            normalized.append(username)
        return normalized


class GroupUpdateRequest(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=120)
    description: str | None = Field(default=None, max_length=500)

    @field_validator("title", "description")
    @classmethod
    def trim_optional_text(cls, value: str | None) -> str | None:
        return value.strip() if value is not None else None


class AddGroupMemberRequest(BaseModel):
    username: str = Field(min_length=1, max_length=30)

    @field_validator("username")
    @classmethod
    def normalize_username(cls, value: str) -> str:
        return value.strip().lower().lstrip("@")


class UpdateGroupRoleRequest(BaseModel):
    role: Literal["admin", "moderator", "member"]


class GroupMemberResponse(BaseModel):
    user: UserPreview
    role: Literal["admin", "moderator", "member"]
    joined_at: datetime
