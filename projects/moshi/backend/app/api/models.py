from enum import StrEnum
from pydantic import BaseModel, Field


class CatalogKind(StrEnum):
    product = "product"
    service = "service"


class CatalogItemPreview(BaseModel):
    id: str
    title: str
    kind: CatalogKind
    price: int | None = Field(default=None, ge=0)
    currency: str = "IDR"
    available: bool = True


class SummaryRequest(BaseModel):
    conversation_id: str
    message_ids: list[str] = Field(default_factory=list)


class SummaryResponse(BaseModel):
    conversation_id: str
    summary: str
    key_points: list[str]
    decisions: list[str]
    action_items: list[str]
    source_message_ids: list[str]
