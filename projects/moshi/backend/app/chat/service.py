from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.chat.models import Conversation, ConversationMember, Message, MessageReceipt
from app.chat.schemas import ConversationResponse, MessageResponse, UserPreview
from app.identity.models import User


def _aware(value: datetime | None) -> datetime | None:
    if value is None or value.tzinfo is not None:
        return value
    return value.replace(tzinfo=UTC)


def ensure_member(db: Session, conversation_id: str, user_id: str) -> ConversationMember | None:
    return db.get(ConversationMember, (conversation_id, user_id))


def message_state(message: Message, viewer_id: str) -> str:
    if message.sender_id != viewer_id:
        return "received"
    peer_receipts = [receipt for receipt in message.receipts if receipt.user_id != viewer_id]
    if any(receipt.read_at is not None for receipt in peer_receipts):
        return "read"
    if any(receipt.delivered_at is not None for receipt in peer_receipts):
        return "delivered"
    return "sent"


def serialize_message(message: Message, viewer_id: str) -> MessageResponse:
    return MessageResponse(
        id=message.id,
        conversation_id=message.conversation_id,
        sender_id=message.sender_id,
        client_message_id=message.client_message_id,
        body=message.body,
        created_at=_aware(message.created_at),
        edited_at=_aware(message.edited_at),
        state=message_state(message, viewer_id),
    )


def get_peer(db: Session, conversation_id: str, user_id: str) -> User | None:
    peer_id = db.scalar(
        select(ConversationMember.user_id).where(
            ConversationMember.conversation_id == conversation_id,
            ConversationMember.user_id != user_id,
        )
    )
    return db.get(User, peer_id) if peer_id else None


def serialize_conversation(db: Session, conversation: Conversation, user_id: str) -> ConversationResponse:
    member = db.get(ConversationMember, (conversation.id, user_id))
    latest = db.scalar(
        select(Message)
        .where(Message.conversation_id == conversation.id)
        .order_by(Message.created_at.desc())
        .limit(1)
    )
    unread_query = select(func.count(Message.id)).where(
        Message.conversation_id == conversation.id,
        Message.sender_id != user_id,
    )
    if member is not None and member.last_read_at is not None:
        unread_query = unread_query.where(Message.created_at > member.last_read_at)
    unread_count = int(db.scalar(unread_query) or 0)
    peer = get_peer(db, conversation.id, user_id) if conversation.kind == "direct" else None
    return ConversationResponse(
        id=conversation.id,
        kind=conversation.kind,
        peer=UserPreview.model_validate(peer) if peer else None,
        latest_message=serialize_message(latest, user_id) if latest else None,
        unread_count=unread_count,
        created_at=_aware(conversation.created_at),
        updated_at=_aware(conversation.updated_at),
    )


def create_message(
    db: Session,
    conversation: Conversation,
    sender_id: str,
    client_message_id: str,
    body: str,
) -> tuple[Message, bool]:
    existing = db.scalar(
        select(Message).where(
            Message.sender_id == sender_id,
            Message.client_message_id == client_message_id,
        )
    )
    if existing is not None:
        return existing, False

    message = Message(
        conversation_id=conversation.id,
        sender_id=sender_id,
        client_message_id=client_message_id,
        body=body.strip(),
    )
    conversation.updated_at = datetime.now(UTC)
    db.add(message)
    db.add(conversation)
    db.flush()

    member_ids = db.scalars(
        select(ConversationMember.user_id).where(
            ConversationMember.conversation_id == conversation.id
        )
    ).all()
    for member_id in member_ids:
        if member_id != sender_id:
            db.add(MessageReceipt(message_id=message.id, user_id=member_id))
    db.commit()
    db.refresh(message)
    return message, True
