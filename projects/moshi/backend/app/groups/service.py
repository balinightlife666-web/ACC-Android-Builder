from __future__ import annotations

from datetime import UTC, datetime

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.chat.models import Conversation, ConversationMember
from app.groups.models import GroupMemberRole, GroupProfile


ROLE_RANK = {"member": 1, "moderator": 2, "admin": 3}


def require_group(db: Session, conversation_id: str) -> tuple[Conversation, GroupProfile]:
    conversation = db.get(Conversation, conversation_id)
    profile = db.get(GroupProfile, conversation_id)
    if conversation is None or conversation.kind != "group" or profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="group not found")
    return conversation, profile


def member_role(db: Session, conversation_id: str, user_id: str) -> str | None:
    membership = db.get(ConversationMember, (conversation_id, user_id))
    if membership is None:
        return None
    role = db.get(GroupMemberRole, (conversation_id, user_id))
    return role.role if role is not None else "member"


def require_group_member(db: Session, conversation_id: str, user_id: str) -> str:
    require_group(db, conversation_id)
    role = member_role(db, conversation_id, user_id)
    if role is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="group not found")
    return role


def require_role(db: Session, conversation_id: str, user_id: str, minimum: str) -> str:
    role = require_group_member(db, conversation_id, user_id)
    if ROLE_RANK.get(role, 0) < ROLE_RANK[minimum]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="insufficient group role")
    return role


def admin_count(db: Session, conversation_id: str) -> int:
    return int(
        db.scalar(
            select(func.count(GroupMemberRole.user_id)).where(
                GroupMemberRole.conversation_id == conversation_id,
                GroupMemberRole.role == "admin",
            )
        )
        or 0
    )


def touch_group(conversation: Conversation, profile: GroupProfile) -> None:
    now = datetime.now(UTC)
    conversation.updated_at = now
    profile.updated_at = now


def can_remove(actor_role: str, target_role: str) -> bool:
    if actor_role == "admin":
        return target_role != "admin"
    if actor_role == "moderator":
        return target_role == "member"
    return False
