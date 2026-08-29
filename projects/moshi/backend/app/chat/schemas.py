from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class UserPreview(BaseModel):
    id: str
    username: str
    display_name: str
    business_mode: bool

    model_config = ConfigDict(from_attributes=True)


class DirectConversationRequest(BaseModel):
    username: str = Field(min_length=3, max_length=30, pattern=r"^[a-zA-Z0-9_.]+$")


class SendMessageRequest(BaseModel):
    client_message_id: str = Field(min_length=8, max_length=64)
    body: str = Field(min_length=1, max_length=8000)
    reply_to_id: str | None = None


class EditMessageRequest(BaseModel):
    body: str = Field(min_length=1, max_length=8000)


class ReactionRequest(BaseModel):
    emoji: str = Field(min_length=1, max_length=16)


class ReadRequest(BaseModel):
    message_id: str


class ReplyPreview(BaseModel):
    id: str
    sender_id: str
    body: str
    is_deleted: bool = False


class ReactionSummary(BaseModel):
    emoji: str
    count: int
    reacted_by_me: bool


class MessageResponse(BaseModel):
    id: str
    conversation_id: str
    sender_id: str
    client_message_id: str
    body: str
    created_at: datetime
    edited_at: datetime | None = None
    deleted_at: datetime | None = None
    is_deleted: bool = False
    state: str = "sent"
    reply_to: ReplyPreview | None = None
    reactions: list[ReactionSummary] = []


class ConversationResponse(BaseModel):
    id: str
    kind: str
    peer: UserPreview | None
    latest_message: MessageResponse | None
    unread_count: int
    created_at: datetime
    updated_at: datetime
