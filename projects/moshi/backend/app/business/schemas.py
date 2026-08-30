from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field, field_validator, model_validator

from app.chat.schemas import UserPreview

CatalogKind = Literal["product", "service"]
Availability = Literal["available", "unavailable", "out_of_stock"]


class BusinessProfileUpsertRequest(BaseModel):
    business_name: str = Field(min_length=1, max_length=120)
    category: str = Field(default="", max_length=80)
    description: str = Field(default="", max_length=1000)
    address: str = Field(default="", max_length=500)
    hours: str = Field(default="", max_length=500)

    @field_validator("business_name", "category", "description", "address", "hours")
    @classmethod
    def trim_text(cls, value: str) -> str:
        return value.strip()


class BusinessProfileResponse(BaseModel):
    user: UserPreview
    business_name: str
    category: str
    description: str
    address: str
    hours: str
    created_at: datetime
    updated_at: datetime


class CatalogCreateRequest(BaseModel):
    kind: CatalogKind
    title: str = Field(min_length=1, max_length=140)
    description: str = Field(default="", max_length=2000)
    price_amount: int | None = Field(default=None, ge=0)
    currency: str = Field(default="IDR", min_length=3, max_length=3)
    availability: Availability = "available"
    stock_qty: int | None = Field(default=None, ge=0)
    image_attachment_id: str | None = None

    @field_validator("title", "description")
    @classmethod
    def trim_text(cls, value: str) -> str:
        return value.strip()

    @field_validator("currency")
    @classmethod
    def normalize_currency(cls, value: str) -> str:
        return value.strip().upper()

    @model_validator(mode="after")
    def service_has_no_stock(self) -> "CatalogCreateRequest":
        if self.kind == "service" and self.stock_qty is not None:
            raise ValueError("service catalog item cannot have stock quantity")
        return self


class CatalogUpdateRequest(BaseModel):
    kind: CatalogKind | None = None
    title: str | None = Field(default=None, min_length=1, max_length=140)
    description: str | None = Field(default=None, max_length=2000)
    price_amount: int | None = Field(default=None, ge=0)
    currency: str | None = Field(default=None, min_length=3, max_length=3)
    availability: Availability | None = None
    stock_qty: int | None = Field(default=None, ge=0)
    image_attachment_id: str | None = None
    clear_image: bool = False

    @field_validator("title", "description")
    @classmethod
    def trim_optional_text(cls, value: str | None) -> str | None:
        return value.strip() if value is not None else None

    @field_validator("currency")
    @classmethod
    def normalize_optional_currency(cls, value: str | None) -> str | None:
        return value.strip().upper() if value is not None else None


class CatalogItemResponse(BaseModel):
    id: str
    owner_id: str
    kind: CatalogKind
    title: str
    description: str
    price_amount: int | None
    currency: str
    availability: Availability
    stock_qty: int | None
    image_path: str | None
    is_active: bool
    created_at: datetime
    updated_at: datetime
