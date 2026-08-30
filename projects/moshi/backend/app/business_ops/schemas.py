from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class QuickReplyCreate(BaseModel):
    shortcut: str = Field(min_length=1, max_length=40)
    title: str = Field(min_length=1, max_length=80)
    body: str = Field(min_length=1, max_length=2000)


class QuickReplyUpdate(BaseModel):
    shortcut: str | None = Field(default=None, min_length=1, max_length=40)
    title: str | None = Field(default=None, min_length=1, max_length=80)
    body: str | None = Field(default=None, min_length=1, max_length=2000)


class QuickReplyResponse(BaseModel):
    id: str
    shortcut: str
    title: str
    body: str
    created_at: datetime
    updated_at: datetime


class LabelCreate(BaseModel):
    name: str = Field(min_length=1, max_length=60)


class LabelResponse(BaseModel):
    id: str
    name: str
    created_at: datetime


OrderStatus = Literal["draft", "awaiting_confirmation", "confirmed", "processing", "completed", "cancelled"]


class OrderStatusUpdate(BaseModel):
    status: OrderStatus
