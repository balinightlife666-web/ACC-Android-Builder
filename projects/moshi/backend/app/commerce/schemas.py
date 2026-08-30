from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class CatalogCardShareRequest(BaseModel):
    client_message_id: str = Field(min_length=8, max_length=64)
    catalog_item_id: str
    body: str = Field(default="", max_length=2000)


class CatalogCardResponse(BaseModel):
    catalog_item_id: str | None
    seller_id: str
    business_name: str
    kind: str
    title: str
    description: str
    price_amount: int | None
    currency: str
    availability: str
    stock_qty: int | None
    image_path: str | None


class OrderDraftCreateRequest(BaseModel):
    client_message_id: str = Field(min_length=8, max_length=64)
    quantity: int = Field(default=1, ge=1, le=999)
    note: str = Field(default="", max_length=500)


class OrderDraftItemResponse(BaseModel):
    id: str
    catalog_item_id: str | None
    source_message_id: str | None
    kind: str
    title: str
    unit_price_amount: int | None
    currency: str
    quantity: int
    image_path: str | None


class OrderDraftResponse(BaseModel):
    id: str
    conversation_id: str
    buyer_id: str
    seller_id: str
    status: str
    note: str
    items: list[OrderDraftItemResponse]
    total_amount: int | None
    currency: str
    created_at: datetime
    updated_at: datetime


class OrderCardResponse(BaseModel):
    order_id: str
    buyer_id: str
    seller_id: str
    status: str
    item_title: str
    quantity: int
    total_amount: int | None
    currency: str


class OrderDraftActionResponse(BaseModel):
    order: OrderDraftResponse
    message: Any
