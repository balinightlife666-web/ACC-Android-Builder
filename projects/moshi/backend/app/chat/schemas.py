from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.commerce.schemas import CatalogCardResponse, OrderCardResponse


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
    body: str = Field(default="", max_length=8000)
    reply_to_id: str | None = None
    attachment_ids: list[str] = Field(default_factory=list, max_length=10)

    @model_validator(mode="after")
    def body_or_attachment(self) -> "SendMessageRequest":
        if not self.body.strip() and not self.attachment_ids:
            raise ValueError("message requires body or attachment")
        return self


class EditMessageRequest(BaseModel):
    body: str = Field(min_length=1, max_length=8000)


class ReactionRequest(BaseModel):
    emoji: str = Field(min_length=1, max_length=16)


class ReadRequest(BaseModel):
    message_id: str


class UploadInitRequest(BaseModel):
    kind: Literal["image", "file"]
    file_name: str = Field(min_length=1, max_length=255)
    content_type: str = Field(min_length=1, max_length=120)
    size_bytes: int = Field(ge=1)


class UploadInitResponse(BaseModel):
    id: str
    kind: str
    file_name: str
    content_type: str
    size_bytes: int
    status: str
    upload_path: str
    created_at: datetime


class AttachmentResponse(BaseModel):
    id: str
    kind: str
    file_name: str
    content_type: str
    size_bytes: int
    status: str
    download_path: str


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
    reactions: list[ReactionSummary] = Field(default_factory=list)
    attachments: list[AttachmentResponse] = Field(default_factory=list)
    catalog_card: CatalogCardResponse | None = None
    order_card: OrderCardResponse | None = None


class GroupPreview(BaseModel):
    title: str
    description: str
    my_role: Literal["admin", "moderator", "member"]
    member_count: int


class ConversationResponse(BaseModel):
    id: str
    kind: str
    peer: UserPreview | None
    group: GroupPreview | None = None
    latest_message: MessageResponse | None
    unread_count: int
    created_at: datetime
    updated_at: datetime
