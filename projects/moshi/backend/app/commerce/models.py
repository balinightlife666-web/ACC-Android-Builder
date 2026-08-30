from __future__ import annotations

from datetime import UTC, datetime
import uuid

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


def utcnow() -> datetime:
    return datetime.now(UTC)


class MessageCatalogCard(Base):
    __tablename__ = "message_catalog_cards"

    message_id: Mapped[str] = mapped_column(ForeignKey("messages.id", ondelete="CASCADE"), primary_key=True)
    catalog_item_id: Mapped[str | None] = mapped_column(ForeignKey("catalog_items.id", ondelete="SET NULL"), nullable=True, index=True)
    seller_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    business_name: Mapped[str] = mapped_column(String(120))
    kind: Mapped[str] = mapped_column(String(20))
    title: Mapped[str] = mapped_column(String(140))
    description: Mapped[str] = mapped_column(Text, default="")
    price_amount: Mapped[int | None] = mapped_column(Integer, nullable=True)
    currency: Mapped[str] = mapped_column(String(3), default="IDR")
    availability: Mapped[str] = mapped_column(String(20), default="available")
    stock_qty: Mapped[int | None] = mapped_column(Integer, nullable=True)
    image_attachment_id: Mapped[str | None] = mapped_column(
        ForeignKey("message_attachments.id", ondelete="SET NULL"), nullable=True, index=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    message = relationship("Message", back_populates="catalog_card")


class OrderDraft(Base):
    __tablename__ = "order_drafts"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    conversation_id: Mapped[str] = mapped_column(ForeignKey("conversations.id", ondelete="CASCADE"), index=True)
    buyer_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    seller_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    status: Mapped[str] = mapped_column(String(20), default="draft", index=True)
    note: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    items: Mapped[list["OrderDraftItem"]] = relationship(back_populates="order", cascade="all, delete-orphan")


class OrderDraftItem(Base):
    __tablename__ = "order_draft_items"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    order_id: Mapped[str] = mapped_column(ForeignKey("order_drafts.id", ondelete="CASCADE"), index=True)
    catalog_item_id: Mapped[str | None] = mapped_column(ForeignKey("catalog_items.id", ondelete="SET NULL"), nullable=True, index=True)
    source_message_id: Mapped[str | None] = mapped_column(ForeignKey("messages.id", ondelete="SET NULL"), nullable=True, index=True)
    kind: Mapped[str] = mapped_column(String(20))
    title: Mapped[str] = mapped_column(String(140))
    unit_price_amount: Mapped[int | None] = mapped_column(Integer, nullable=True)
    currency: Mapped[str] = mapped_column(String(3), default="IDR")
    quantity: Mapped[int] = mapped_column(Integer, default=1)
    image_attachment_id: Mapped[str | None] = mapped_column(
        ForeignKey("message_attachments.id", ondelete="SET NULL"), nullable=True, index=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    order: Mapped[OrderDraft] = relationship(back_populates="items")


class MessageOrderCard(Base):
    __tablename__ = "message_order_cards"

    message_id: Mapped[str] = mapped_column(ForeignKey("messages.id", ondelete="CASCADE"), primary_key=True)
    order_id: Mapped[str] = mapped_column(ForeignKey("order_drafts.id", ondelete="CASCADE"), unique=True, index=True)
    buyer_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    seller_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    status: Mapped[str] = mapped_column(String(20), default="draft")
    item_title: Mapped[str] = mapped_column(String(140))
    quantity: Mapped[int] = mapped_column(Integer, default=1)
    total_amount: Mapped[int | None] = mapped_column(Integer, nullable=True)
    currency: Mapped[str] = mapped_column(String(3), default="IDR")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    message = relationship("Message", back_populates="order_card")
