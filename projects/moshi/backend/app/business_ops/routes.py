from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.business.models import BusinessProfile, CatalogItem
from app.business_ops.models import BusinessLabel, CustomerLabelAssignment, QuickReply
from app.business_ops.schemas import (
    LabelCreate,
    LabelResponse,
    OrderStatusUpdate,
    QuickReplyCreate,
    QuickReplyResponse,
    QuickReplyUpdate,
)
from app.chat.models import ConversationMember, Message
from app.chat.realtime import manager
from app.chat.service import serialize_message
from app.commerce.models import MessageOrderCard, OrderDraft
from app.commerce.schemas import OrderDraftResponse
from app.commerce.service import serialize_order
from app.identity.deps import get_current_user, get_db
from app.identity.models import User

router = APIRouter()


def require_business(db: Session, user: User) -> BusinessProfile:
    profile = db.get(BusinessProfile, user.id)
    if not user.business_mode or profile is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="business mode required")
    return profile


def quick_reply_response(item: QuickReply) -> QuickReplyResponse:
    return QuickReplyResponse(
        id=item.id,
        shortcut=item.shortcut,
        title=item.title,
        body=item.body,
        created_at=item.created_at,
        updated_at=item.updated_at,
    )


def label_response(item: BusinessLabel) -> LabelResponse:
    return LabelResponse(id=item.id, name=item.name, created_at=item.created_at)


@router.get("/business/quick-replies", response_model=list[QuickReplyResponse])
def list_quick_replies(user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[QuickReplyResponse]:
    require_business(db, user)
    items = db.scalars(select(QuickReply).where(QuickReply.owner_id == user.id).order_by(QuickReply.shortcut.asc())).all()
    return [quick_reply_response(item) for item in items]


@router.post("/business/quick-replies", response_model=QuickReplyResponse, status_code=201)
def create_quick_reply(payload: QuickReplyCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> QuickReplyResponse:
    require_business(db, user)
    shortcut = payload.shortcut.strip().lower().lstrip("/")
    if not shortcut:
        raise HTTPException(status_code=400, detail="shortcut required")
    duplicate = db.scalar(select(QuickReply).where(QuickReply.owner_id == user.id, QuickReply.shortcut == shortcut))
    if duplicate is not None:
        raise HTTPException(status_code=409, detail="shortcut already exists")
    item = QuickReply(owner_id=user.id, shortcut=shortcut, title=payload.title.strip(), body=payload.body.strip())
    db.add(item)
    db.commit()
    db.refresh(item)
    return quick_reply_response(item)


@router.patch("/business/quick-replies/{reply_id}", response_model=QuickReplyResponse)
def update_quick_reply(reply_id: str, payload: QuickReplyUpdate, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> QuickReplyResponse:
    require_business(db, user)
    item = db.get(QuickReply, reply_id)
    if item is None or item.owner_id != user.id:
        raise HTTPException(status_code=404, detail="quick reply not found")
    if payload.shortcut is not None:
        shortcut = payload.shortcut.strip().lower().lstrip("/")
        duplicate = db.scalar(select(QuickReply).where(QuickReply.owner_id == user.id, QuickReply.shortcut == shortcut, QuickReply.id != item.id))
        if duplicate is not None:
            raise HTTPException(status_code=409, detail="shortcut already exists")
        item.shortcut = shortcut
    if payload.title is not None:
        item.title = payload.title.strip()
    if payload.body is not None:
        item.body = payload.body.strip()
    item.updated_at = datetime.now(UTC)
    db.add(item)
    db.commit()
    db.refresh(item)
    return quick_reply_response(item)


@router.delete("/business/quick-replies/{reply_id}", status_code=204)
def delete_quick_reply(reply_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> None:
    require_business(db, user)
    item = db.get(QuickReply, reply_id)
    if item is None or item.owner_id != user.id:
        raise HTTPException(status_code=404, detail="quick reply not found")
    db.delete(item)
    db.commit()


@router.get("/business/labels", response_model=list[LabelResponse])
def list_labels(user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[LabelResponse]:
    require_business(db, user)
    labels = db.scalars(select(BusinessLabel).where(BusinessLabel.owner_id == user.id).order_by(BusinessLabel.name.asc())).all()
    return [label_response(item) for item in labels]


@router.post("/business/labels", response_model=LabelResponse, status_code=201)
def create_label(payload: LabelCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> LabelResponse:
    require_business(db, user)
    name = payload.name.strip()
    duplicate = db.scalar(select(BusinessLabel).where(BusinessLabel.owner_id == user.id, BusinessLabel.name == name))
    if duplicate is not None:
        raise HTTPException(status_code=409, detail="label already exists")
    item = BusinessLabel(owner_id=user.id, name=name)
    db.add(item)
    db.commit()
    db.refresh(item)
    return label_response(item)


@router.delete("/business/labels/{label_id}", status_code=204)
def delete_label(label_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> None:
    require_business(db, user)
    item = db.get(BusinessLabel, label_id)
    if item is None or item.owner_id != user.id:
        raise HTTPException(status_code=404, detail="label not found")
    db.delete(item)
    db.commit()


def require_customer(db: Session, username: str, owner_id: str) -> User:
    customer = db.scalar(select(User).where(User.username == username.strip().lstrip("@")))
    if customer is None or customer.id == owner_id:
        raise HTTPException(status_code=404, detail="customer not found")
    return customer


@router.get("/business/customers/{username}/labels", response_model=list[LabelResponse])
def customer_labels(username: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[LabelResponse]:
    require_business(db, user)
    customer = require_customer(db, username, user.id)
    labels = db.scalars(
        select(BusinessLabel)
        .join(CustomerLabelAssignment, CustomerLabelAssignment.label_id == BusinessLabel.id)
        .where(BusinessLabel.owner_id == user.id, CustomerLabelAssignment.customer_id == customer.id)
        .order_by(BusinessLabel.name.asc())
    ).all()
    return [label_response(item) for item in labels]


@router.post("/business/customers/{username}/labels/{label_id}", response_model=list[LabelResponse])
def assign_customer_label(username: str, label_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[LabelResponse]:
    require_business(db, user)
    customer = require_customer(db, username, user.id)
    label = db.get(BusinessLabel, label_id)
    if label is None or label.owner_id != user.id:
        raise HTTPException(status_code=404, detail="label not found")
    existing = db.get(CustomerLabelAssignment, (label.id, customer.id))
    if existing is None:
        db.add(CustomerLabelAssignment(label_id=label.id, customer_id=customer.id))
        db.commit()
    return customer_labels(username, user, db)


@router.delete("/business/customers/{username}/labels/{label_id}", response_model=list[LabelResponse])
def remove_customer_label(username: str, label_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[LabelResponse]:
    require_business(db, user)
    customer = require_customer(db, username, user.id)
    label = db.get(BusinessLabel, label_id)
    if label is None or label.owner_id != user.id:
        raise HTTPException(status_code=404, detail="label not found")
    existing = db.get(CustomerLabelAssignment, (label.id, customer.id))
    if existing is not None:
        db.delete(existing)
        db.commit()
    return customer_labels(username, user, db)


def allowed_transition(order: OrderDraft, user_id: str, target: str) -> bool:
    if target == order.status:
        return True
    if user_id == order.buyer_id:
        return (order.status, target) in {
            ("draft", "awaiting_confirmation"),
            ("draft", "cancelled"),
            ("awaiting_confirmation", "cancelled"),
        }
    if user_id == order.seller_id:
        return (order.status, target) in {
            ("draft", "confirmed"),
            ("awaiting_confirmation", "confirmed"),
            ("draft", "cancelled"),
            ("awaiting_confirmation", "cancelled"),
            ("confirmed", "processing"),
            ("confirmed", "cancelled"),
            ("processing", "completed"),
            ("processing", "cancelled"),
        }
    return False


def reserve_stock(db: Session, order: OrderDraft) -> None:
    for line in order.items:
        if line.kind != "product" or line.catalog_item_id is None:
            continue
        item = db.get(CatalogItem, line.catalog_item_id)
        if item is None or not item.is_active or item.stock_qty is None or item.stock_qty < line.quantity:
            raise HTTPException(status_code=409, detail=f"insufficient stock for {line.title}")
    for line in order.items:
        if line.kind != "product" or line.catalog_item_id is None:
            continue
        item = db.get(CatalogItem, line.catalog_item_id)
        if item is not None and item.stock_qty is not None:
            item.stock_qty -= line.quantity
            if item.stock_qty == 0:
                item.availability = "unavailable"
            db.add(item)


def restore_stock(db: Session, order: OrderDraft) -> None:
    for line in order.items:
        if line.kind != "product" or line.catalog_item_id is None:
            continue
        item = db.get(CatalogItem, line.catalog_item_id)
        if item is not None and item.stock_qty is not None:
            item.stock_qty += line.quantity
            if item.stock_qty > 0 and item.availability == "unavailable":
                item.availability = "available"
            db.add(item)


@router.patch("/orders/{order_id}/status", response_model=OrderDraftResponse)
async def update_order_status(order_id: str, payload: OrderStatusUpdate, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> OrderDraftResponse:
    order = db.get(OrderDraft, order_id)
    if order is None or user.id not in {order.buyer_id, order.seller_id}:
        raise HTTPException(status_code=404, detail="order not found")
    target = payload.status
    if not allowed_transition(order, user.id, target):
        raise HTTPException(status_code=409, detail=f"cannot move order from {order.status} to {target}")
    if target == order.status:
        return serialize_order(order)

    previous = order.status
    if target == "confirmed":
        reserve_stock(db, order)
    elif target == "cancelled" and previous in {"confirmed", "processing"}:
        restore_stock(db, order)

    order.status = target
    order.updated_at = datetime.now(UTC)
    db.add(order)

    card = db.scalar(select(MessageOrderCard).where(MessageOrderCard.order_id == order.id))
    message: Message | None = None
    if card is not None:
        card.status = target
        db.add(card)
        message = db.get(Message, card.message_id)
        if message is not None:
            message.body = f"🧾 Order · {card.item_title} ×{card.quantity} · {target.replace('_', ' ').title()}"
            db.add(message)

    db.commit()
    db.refresh(order)
    if message is not None:
        member_ids = db.scalars(select(ConversationMember.user_id).where(ConversationMember.conversation_id == order.conversation_id)).all()
        for member_id in member_ids:
            await manager.send_user(member_id, {"type": "message.updated", "message": serialize_message(message, member_id).model_dump(mode="json")})
    return serialize_order(order)
