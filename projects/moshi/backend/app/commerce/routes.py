from __future__ import annotations

from datetime import UTC, datetime
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.business.models import BusinessProfile, CatalogItem
from app.chat.models import Conversation, ConversationMember, Message, MessageAttachment, MessageReceipt
from app.chat.realtime import manager
from app.chat.schemas import MessageResponse
from app.chat.service import create_message, ensure_member, serialize_message
from app.commerce.models import MessageCatalogCard, MessageOrderCard, OrderDraft, OrderDraftItem
from app.commerce.schemas import CatalogCardShareRequest, OrderDraftActionResponse, OrderDraftCreateRequest, OrderDraftResponse
from app.commerce.service import serialize_order
from app.core.config import settings
from app.identity.deps import get_current_user, get_db
from app.identity.models import User

router = APIRouter()


async def deliver_new_message(db: Session, message: Message, sender_id: str) -> None:
    recipient_ids = db.scalars(
        select(ConversationMember.user_id).where(
            ConversationMember.conversation_id == message.conversation_id,
            ConversationMember.user_id != sender_id,
        )
    ).all()
    delivered_any = False
    for recipient_id in recipient_ids:
        delivered = await manager.send_user(
            recipient_id,
            {"type": "message.created", "message": serialize_message(message, recipient_id).model_dump(mode="json")},
        )
        if delivered:
            receipt = db.get(MessageReceipt, (message.id, recipient_id))
            if receipt is not None and receipt.delivered_at is None:
                receipt.delivered_at = datetime.now(UTC)
                db.add(receipt)
                delivered_any = True
    if delivered_any:
        db.commit()
        db.refresh(message)


def require_conversation(db: Session, conversation_id: str, user_id: str) -> Conversation:
    conversation = db.get(Conversation, conversation_id)
    if conversation is None or ensure_member(db, conversation_id, user_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="conversation not found")
    return conversation


@router.post(
    "/conversations/{conversation_id}/catalog-cards",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
)
async def share_catalog_card(
    conversation_id: str,
    payload: CatalogCardShareRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    conversation = require_conversation(db, conversation_id, user.id)
    item = db.get(CatalogItem, payload.catalog_item_id)
    profile = db.get(BusinessProfile, user.id)
    if item is None or item.owner_id != user.id or not item.is_active or profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="catalog item not found")

    message, created = create_message(
        db,
        conversation,
        user.id,
        payload.client_message_id,
        payload.body,
        commit=False,
    )
    if created:
        db.add(
            MessageCatalogCard(
                message_id=message.id,
                catalog_item_id=item.id,
                seller_id=user.id,
                business_name=profile.business_name,
                kind=item.kind,
                title=item.title,
                description=item.description,
                price_amount=item.price_amount,
                currency=item.currency,
                availability=item.availability,
                stock_qty=item.stock_qty,
                image_attachment_id=item.image_attachment_id,
            )
        )
        db.commit()
        db.refresh(message)
        await deliver_new_message(db, message, user.id)
    else:
        existing_card = db.get(MessageCatalogCard, message.id)
        if existing_card is None or existing_card.catalog_item_id != item.id:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="client message id already used")
    return serialize_message(message, user.id)


@router.get("/commerce/catalog-cards/{message_id}/image")
def catalog_card_image(
    message_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FileResponse:
    message = db.get(Message, message_id)
    card = db.get(MessageCatalogCard, message_id)
    if (
        message is None
        or message.deleted_at is not None
        or card is None
        or card.image_attachment_id is None
        or ensure_member(db, message.conversation_id, user.id) is None
    ):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="catalog card image not found")
    attachment = db.get(MessageAttachment, card.image_attachment_id)
    if attachment is None or attachment.kind != "image" or attachment.status != "ready":
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="catalog card image not found")
    file_path = Path(settings.uploads_dir) / attachment.storage_key
    if not file_path.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="catalog card image content missing")
    return FileResponse(
        path=file_path,
        media_type=attachment.content_type,
        filename=attachment.file_name,
        headers={"X-Content-Type-Options": "nosniff", "Cache-Control": "private, max-age=300"},
    )


@router.post(
    "/conversations/{conversation_id}/catalog-cards/{message_id}/order",
    response_model=OrderDraftActionResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_order_draft_from_card(
    conversation_id: str,
    message_id: str,
    payload: OrderDraftCreateRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> OrderDraftActionResponse:
    conversation = require_conversation(db, conversation_id, user.id)
    if conversation.kind != "direct":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="orders must be created in a direct chat")

    source_message = db.get(Message, message_id)
    card = db.get(MessageCatalogCard, message_id)
    if source_message is None or source_message.conversation_id != conversation_id or source_message.deleted_at is not None or card is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="catalog card not found")
    if card.seller_id == user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="seller cannot order own catalog item")

    existing_message = db.scalar(
        select(Message).where(Message.sender_id == user.id, Message.client_message_id == payload.client_message_id)
    )
    if existing_message is not None:
        existing_card = db.get(MessageOrderCard, existing_message.id)
        if existing_card is None or existing_message.conversation_id != conversation_id:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="client message id already used")
        existing_order = db.get(OrderDraft, existing_card.order_id)
        if existing_order is None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="order draft unavailable")
        return OrderDraftActionResponse(
            order=serialize_order(existing_order),
            message=serialize_message(existing_message, user.id),
        )

    item = db.get(CatalogItem, card.catalog_item_id) if card.catalog_item_id else None
    if item is None or not item.is_active or item.owner_id != card.seller_id:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="catalog item is no longer available")
    if item.availability != "available":
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="catalog item is not available")
    if item.kind == "product" and item.stock_qty is not None and payload.quantity > item.stock_qty:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="requested quantity exceeds current stock")

    message, created = create_message(
        db,
        conversation,
        user.id,
        payload.client_message_id,
        "",
        reply_to_id=source_message.id,
        commit=False,
    )
    if not created:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="client message id already used")

    order = OrderDraft(
        conversation_id=conversation.id,
        buyer_id=user.id,
        seller_id=card.seller_id,
        status="draft",
        note=payload.note.strip(),
    )
    db.add(order)
    db.flush()
    order_item = OrderDraftItem(
        order_id=order.id,
        catalog_item_id=item.id,
        source_message_id=source_message.id,
        kind=item.kind,
        title=item.title,
        unit_price_amount=item.price_amount,
        currency=item.currency,
        quantity=payload.quantity,
        image_attachment_id=item.image_attachment_id,
    )
    order.items.append(order_item)
    total_amount = item.price_amount * payload.quantity if item.price_amount is not None else None
    db.add(
        MessageOrderCard(
            message_id=message.id,
            order_id=order.id,
            buyer_id=user.id,
            seller_id=card.seller_id,
            status="draft",
            item_title=item.title,
            quantity=payload.quantity,
            total_amount=total_amount,
            currency=item.currency,
        )
    )
    db.commit()
    db.refresh(message)
    db.refresh(order)
    await deliver_new_message(db, message, user.id)
    return OrderDraftActionResponse(order=serialize_order(order), message=serialize_message(message, user.id))


@router.get("/orders/drafts", response_model=list[OrderDraftResponse])
def list_my_order_drafts(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[OrderDraftResponse]:
    orders = db.scalars(
        select(OrderDraft)
        .where(or_(OrderDraft.buyer_id == user.id, OrderDraft.seller_id == user.id))
        .order_by(OrderDraft.updated_at.desc())
        .limit(100)
    ).all()
    return [serialize_order(order) for order in orders]
