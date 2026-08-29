from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.chat.models import Conversation, ConversationMember, Message, MessageReaction, MessageReceipt
from app.chat.realtime import manager
from app.chat.schemas import (
    ConversationResponse,
    DirectConversationRequest,
    EditMessageRequest,
    MessageResponse,
    ReactionRequest,
    ReadRequest,
    SendMessageRequest,
    UserPreview,
)
from app.chat.service import create_message, ensure_member, serialize_conversation, serialize_message
from app.identity.deps import authenticate_access_token, get_current_user, get_db
from app.identity.models import User

router = APIRouter()


async def broadcast_message(db: Session, message: Message, event_type: str, exclude_user_id: str | None = None) -> None:
    member_ids = db.scalars(
        select(ConversationMember.user_id).where(ConversationMember.conversation_id == message.conversation_id)
    ).all()
    for member_id in member_ids:
        if member_id == exclude_user_id:
            continue
        await manager.send_user(
            member_id,
            {"type": event_type, "message": serialize_message(message, member_id).model_dump(mode="json")},
        )


@router.get("/users/search", response_model=list[UserPreview])
def search_users(q: str = Query(min_length=1, max_length=50), user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[UserPreview]:
    term = f"%{q.strip()}%"
    users = db.scalars(
        select(User).where(User.id != user.id, or_(User.username.ilike(term), User.display_name.ilike(term))).order_by(User.username.asc()).limit(20)
    ).all()
    return [UserPreview.model_validate(item) for item in users]


@router.post("/conversations/direct", response_model=ConversationResponse)
def create_direct_conversation(payload: DirectConversationRequest, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> ConversationResponse:
    peer = db.scalar(select(User).where(User.username == payload.username))
    if peer is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="user not found")
    if peer.id == user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="cannot chat with yourself")
    direct_key = ":".join(sorted((user.id, peer.id)))
    conversation = db.scalar(select(Conversation).where(Conversation.direct_key == direct_key))
    if conversation is None:
        conversation = Conversation(kind="direct", direct_key=direct_key)
        db.add(conversation)
        db.flush()
        db.add_all([
            ConversationMember(conversation_id=conversation.id, user_id=user.id),
            ConversationMember(conversation_id=conversation.id, user_id=peer.id),
        ])
        db.commit()
        db.refresh(conversation)
    return serialize_conversation(db, conversation, user.id)


@router.get("/conversations", response_model=list[ConversationResponse])
def list_conversations(user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[ConversationResponse]:
    conversations = db.scalars(
        select(Conversation).join(ConversationMember, ConversationMember.conversation_id == Conversation.id).where(ConversationMember.user_id == user.id).order_by(Conversation.updated_at.desc())
    ).all()
    return [serialize_conversation(db, item, user.id) for item in conversations]


@router.get("/conversations/{conversation_id}/messages", response_model=list[MessageResponse])
def list_messages(conversation_id: str, after: datetime | None = None, limit: int = Query(default=100, ge=1, le=200), user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[MessageResponse]:
    if ensure_member(db, conversation_id, user.id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="conversation not found")
    query = select(Message).where(Message.conversation_id == conversation_id)
    if after is not None:
        query = query.where(Message.created_at > after)
    messages = db.scalars(query.order_by(Message.created_at.asc()).limit(limit)).all()
    now = datetime.now(UTC)
    changed = False
    for message in messages:
        if message.sender_id == user.id:
            continue
        receipt = db.get(MessageReceipt, (message.id, user.id))
        if receipt is not None and receipt.delivered_at is None:
            receipt.delivered_at = now
            db.add(receipt)
            changed = True
    if changed:
        db.commit()
    return [serialize_message(item, user.id) for item in messages]


@router.post("/conversations/{conversation_id}/messages", response_model=MessageResponse, status_code=201)
async def send_message(conversation_id: str, payload: SendMessageRequest, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> MessageResponse:
    conversation = db.get(Conversation, conversation_id)
    if conversation is None or ensure_member(db, conversation_id, user.id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="conversation not found")
    try:
        message, created = create_message(db, conversation, user.id, payload.client_message_id, payload.body, payload.reply_to_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    if created:
        recipient_ids = db.scalars(
            select(ConversationMember.user_id).where(ConversationMember.conversation_id == conversation_id, ConversationMember.user_id != user.id)
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
    return serialize_message(message, user.id)


@router.patch("/conversations/{conversation_id}/messages/{message_id}", response_model=MessageResponse)
async def edit_message(conversation_id: str, message_id: str, payload: EditMessageRequest, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> MessageResponse:
    message = db.get(Message, message_id)
    if message is None or message.conversation_id != conversation_id or ensure_member(db, conversation_id, user.id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="message not found")
    if message.sender_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="only sender can edit message")
    if message.deleted_at is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="deleted message cannot be edited")
    message.body = payload.body.strip()
    message.edited_at = datetime.now(UTC)
    db.add(message)
    db.commit()
    db.refresh(message)
    await broadcast_message(db, message, "message.updated", exclude_user_id=user.id)
    return serialize_message(message, user.id)


@router.delete("/conversations/{conversation_id}/messages/{message_id}", response_model=MessageResponse)
async def delete_message(conversation_id: str, message_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> MessageResponse:
    message = db.get(Message, message_id)
    if message is None or message.conversation_id != conversation_id or ensure_member(db, conversation_id, user.id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="message not found")
    if message.sender_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="only sender can delete message")
    if message.deleted_at is None:
        message.deleted_at = datetime.now(UTC)
        message.body = ""
        db.add(message)
        db.commit()
        db.refresh(message)
    await broadcast_message(db, message, "message.updated", exclude_user_id=user.id)
    return serialize_message(message, user.id)


@router.post("/conversations/{conversation_id}/messages/{message_id}/reactions", response_model=MessageResponse)
async def toggle_reaction(conversation_id: str, message_id: str, payload: ReactionRequest, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> MessageResponse:
    message = db.get(Message, message_id)
    if message is None or message.conversation_id != conversation_id or ensure_member(db, conversation_id, user.id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="message not found")
    emoji = payload.emoji.strip()
    existing = db.scalar(
        select(MessageReaction).where(
            MessageReaction.message_id == message_id,
            MessageReaction.user_id == user.id,
            MessageReaction.emoji == emoji,
        )
    )
    if existing is None:
        db.add(MessageReaction(message_id=message_id, user_id=user.id, emoji=emoji))
    else:
        db.delete(existing)
    db.commit()
    db.refresh(message)
    await broadcast_message(db, message, "message.updated", exclude_user_id=user.id)
    return serialize_message(message, user.id)


@router.post("/conversations/{conversation_id}/read", status_code=204)
async def mark_read(conversation_id: str, payload: ReadRequest, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> None:
    member = ensure_member(db, conversation_id, user.id)
    target = db.get(Message, payload.message_id)
    if member is None or target is None or target.conversation_id != conversation_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="message not found")
    now = datetime.now(UTC)
    member.last_read_at = max(_aware_datetime(member.last_read_at), _aware_datetime(target.created_at)) if member.last_read_at else target.created_at
    db.add(member)
    incoming = db.scalars(
        select(Message).where(
            Message.conversation_id == conversation_id,
            Message.sender_id != user.id,
            Message.created_at <= target.created_at,
        )
    ).all()
    read_ids: list[str] = []
    sender_ids: set[str] = set()
    for message in incoming:
        receipt = db.get(MessageReceipt, (message.id, user.id))
        if receipt is None:
            continue
        if receipt.delivered_at is None:
            receipt.delivered_at = now
        if receipt.read_at is None:
            receipt.read_at = now
            read_ids.append(message.id)
        db.add(receipt)
        sender_ids.add(message.sender_id)
    db.commit()
    for sender_id in sender_ids:
        await manager.send_user(
            sender_id,
            {"type": "message.read", "conversation_id": conversation_id, "message_id": target.id, "message_ids": read_ids, "reader_id": user.id},
        )


def _aware_datetime(value: datetime) -> datetime:
    return value if value.tzinfo is not None else value.replace(tzinfo=UTC)


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str = Query()) -> None:
    db = next(get_db())
    user: User | None = None
    try:
        user = authenticate_access_token(token, db)
        await manager.connect(user.id, websocket)
        await websocket.send_json({"type": "ready", "user_id": user.id})
        while True:
            payload = await websocket.receive_json()
            if payload.get("type") == "ping":
                await websocket.send_json({"type": "pong"})
    except HTTPException:
        await websocket.close(code=4401)
    except WebSocketDisconnect:
        pass
    finally:
        if user is not None:
            await manager.disconnect(user.id, websocket)
        db.close()
