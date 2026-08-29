from __future__ import annotations

from collections import defaultdict
from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.chat.models import Conversation, ConversationMember, Message, MessageAttachment, MessageReaction, MessageReceipt
from app.chat.schemas import AttachmentResponse, ConversationResponse, GroupPreview, MessageResponse, ReactionSummary, ReplyPreview, UserPreview
from app.groups.models import GroupMemberRole, GroupProfile
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


def reaction_summary(message: Message, viewer_id: str) -> list[ReactionSummary]:
    grouped: dict[str, list[MessageReaction]] = defaultdict(list)
    for reaction in message.reactions:
        grouped[reaction.emoji].append(reaction)
    return [
        ReactionSummary(
            emoji=emoji,
            count=len(items),
            reacted_by_me=any(item.user_id == viewer_id for item in items),
        )
        for emoji, items in sorted(grouped.items())
    ]


def attachment_summary(message: Message) -> list[AttachmentResponse]:
    return [
        AttachmentResponse(
            id=item.id,
            kind=item.kind,
            file_name=item.file_name,
            content_type=item.content_type,
            size_bytes=item.size_bytes,
            status=item.status,
            download_path=f"/v1/attachments/{item.id}",
        )
        for item in message.attachments
        if item.status == "attached"
    ]


def serialize_message(message: Message, viewer_id: str) -> MessageResponse:
    reply = message.reply_to
    deleted = message.deleted_at is not None
    return MessageResponse(
        id=message.id,
        conversation_id=message.conversation_id,
        sender_id=message.sender_id,
        client_message_id=message.client_message_id,
        body="" if deleted else message.body,
        created_at=_aware(message.created_at),
        edited_at=_aware(message.edited_at),
        deleted_at=_aware(message.deleted_at),
        is_deleted=deleted,
        state=message_state(message, viewer_id),
        reply_to=(
            ReplyPreview(
                id=reply.id,
                sender_id=reply.sender_id,
                body="" if reply.deleted_at is not None else reply.body,
                is_deleted=reply.deleted_at is not None,
            )
            if reply is not None
            else None
        ),
        reactions=reaction_summary(message, viewer_id),
        attachments=[] if deleted else attachment_summary(message),
    )


def get_peer(db: Session, conversation_id: str, user_id: str) -> User | None:
    peer_id = db.scalar(
        select(ConversationMember.user_id).where(
            ConversationMember.conversation_id == conversation_id,
            ConversationMember.user_id != user_id,
        )
    )
    return db.get(User, peer_id) if peer_id else None


def group_preview(db: Session, conversation_id: str, user_id: str) -> GroupPreview | None:
    profile = db.get(GroupProfile, conversation_id)
    if profile is None:
        return None
    role_row = db.get(GroupMemberRole, (conversation_id, user_id))
    member_count = int(
        db.scalar(
            select(func.count(ConversationMember.user_id)).where(
                ConversationMember.conversation_id == conversation_id
            )
        )
        or 0
    )
    return GroupPreview(
        title=profile.title,
        description=profile.description,
        my_role=role_row.role if role_row is not None else "member",
        member_count=member_count,
    )


def serialize_conversation(db: Session, conversation: Conversation, user_id: str) -> ConversationResponse:
    member = db.get(ConversationMember, (conversation.id, user_id))
    latest = db.scalar(
        select(Message).where(Message.conversation_id == conversation.id).order_by(Message.created_at.desc()).limit(1)
    )
    unread_query = select(func.count(Message.id)).where(
        Message.conversation_id == conversation.id,
        Message.sender_id != user_id,
    )
    if member is not None and member.last_read_at is not None:
        unread_query = unread_query.where(Message.created_at > member.last_read_at)
    unread_count = int(db.scalar(unread_query) or 0)
    peer = get_peer(db, conversation.id, user_id) if conversation.kind == "direct" else None
    group = group_preview(db, conversation.id, user_id) if conversation.kind == "group" else None
    return ConversationResponse(
        id=conversation.id,
        kind=conversation.kind,
        peer=UserPreview.model_validate(peer) if peer else None,
        group=group,
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
    reply_to_id: str | None = None,
    attachment_ids: list[str] | None = None,
) -> tuple[Message, bool]:
    existing = db.scalar(
        select(Message).where(
            Message.sender_id == sender_id,
            Message.client_message_id == client_message_id,
        )
    )
    if existing is not None:
        return existing, False

    reply_to = None
    if reply_to_id is not None:
        reply_to = db.get(Message, reply_to_id)
        if reply_to is None or reply_to.conversation_id != conversation.id:
            raise ValueError("reply target not found")

    requested_attachment_ids = list(attachment_ids or [])
    if len(requested_attachment_ids) != len(set(requested_attachment_ids)):
        raise ValueError("duplicate attachment id")
    attachments: list[MessageAttachment] = []
    if requested_attachment_ids:
        attachments = list(
            db.scalars(
                select(MessageAttachment).where(MessageAttachment.id.in_(requested_attachment_ids))
            ).all()
        )
        if len(attachments) != len(requested_attachment_ids):
            raise ValueError("attachment not found")
        by_id = {item.id: item for item in attachments}
        attachments = [by_id[item_id] for item_id in requested_attachment_ids]
        for item in attachments:
            if item.owner_id != sender_id:
                raise ValueError("attachment not owned by sender")
            if item.status != "ready" or item.message_id is not None:
                raise ValueError("attachment is not ready")

    message = Message(
        conversation_id=conversation.id,
        sender_id=sender_id,
        client_message_id=client_message_id,
        body=body.strip(),
        reply_to_id=reply_to.id if reply_to else None,
    )
    conversation.updated_at = datetime.now(UTC)
    db.add(message)
    db.add(conversation)
    db.flush()

    for attachment in attachments:
        attachment.message_id = message.id
        attachment.status = "attached"
        db.add(attachment)

    member_ids = db.scalars(
        select(ConversationMember.user_id).where(ConversationMember.conversation_id == conversation.id)
    ).all()
    for member_id in member_ids:
        if member_id != sender_id:
            db.add(MessageReceipt(message_id=message.id, user_id=member_id))
    db.commit()
    db.refresh(message)
    return message, True
