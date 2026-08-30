from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends, HTTPException, status

from app.chat.models import Conversation, ConversationMember
from app.chat.schemas import ConversationResponse, UserPreview
from app.chat.service import serialize_conversation
from app.groups.models import GroupMemberRole, GroupProfile
from app.groups.schemas import (
    AddGroupMemberRequest,
    GroupCreateRequest,
    GroupMemberResponse,
    GroupUpdateRequest,
    UpdateGroupRoleRequest,
)
from app.groups.service import (
    admin_count,
    can_remove,
    member_role,
    require_group,
    require_group_member,
    require_role,
    touch_group,
)
from app.identity.deps import get_current_user, get_db
from app.identity.models import User

router = APIRouter()


def _member_response(db: Session, membership: ConversationMember) -> GroupMemberResponse:
    user = db.get(User, membership.user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="member user missing")
    role = member_role(db, membership.conversation_id, membership.user_id) or "member"
    return GroupMemberResponse(
        user=UserPreview.model_validate(user),
        role=role,
        joined_at=membership.joined_at,
    )


@router.post("/groups", response_model=ConversationResponse, status_code=status.HTTP_201_CREATED)
def create_group(
    payload: GroupCreateRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ConversationResponse:
    requested = [name for name in payload.usernames if name != user.username]
    users: list[User] = []
    if requested:
        users = list(db.scalars(select(User).where(User.username.in_(requested))).all())
        found = {item.username for item in users}
        missing = [name for name in requested if name not in found]
        if missing:
            missing_text = ", ".join(f"@{name}" for name in missing)
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"users not found: {missing_text}")

    conversation = Conversation(kind="group")
    db.add(conversation)
    db.flush()
    profile = GroupProfile(
        conversation_id=conversation.id,
        title=payload.title,
        description=payload.description,
        created_by=user.id,
    )
    db.add(profile)
    db.add(ConversationMember(conversation_id=conversation.id, user_id=user.id))
    db.add(GroupMemberRole(conversation_id=conversation.id, user_id=user.id, role="admin"))
    for item in users:
        db.add(ConversationMember(conversation_id=conversation.id, user_id=item.id))
        db.add(GroupMemberRole(conversation_id=conversation.id, user_id=item.id, role="member"))
    db.commit()
    db.refresh(conversation)
    return serialize_conversation(db, conversation, user.id)


@router.patch("/groups/{group_id}", response_model=ConversationResponse)
def update_group(
    group_id: str,
    payload: GroupUpdateRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ConversationResponse:
    require_role(db, group_id, user.id, "admin")
    conversation, profile = require_group(db, group_id)
    if payload.title is not None:
        profile.title = payload.title
    if payload.description is not None:
        profile.description = payload.description
    touch_group(conversation, profile)
    db.add_all([conversation, profile])
    db.commit()
    db.refresh(conversation)
    return serialize_conversation(db, conversation, user.id)


@router.get("/groups/{group_id}/members", response_model=list[GroupMemberResponse])
def list_group_members(
    group_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[GroupMemberResponse]:
    require_group_member(db, group_id, user.id)
    memberships = list(
        db.scalars(
            select(ConversationMember)
            .where(ConversationMember.conversation_id == group_id)
            .order_by(ConversationMember.joined_at.asc())
        ).all()
    )
    return [_member_response(db, item) for item in memberships]


@router.post("/groups/{group_id}/members", response_model=GroupMemberResponse, status_code=status.HTTP_201_CREATED)
def add_group_member(
    group_id: str,
    payload: AddGroupMemberRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> GroupMemberResponse:
    require_role(db, group_id, user.id, "moderator")
    conversation, profile = require_group(db, group_id)
    target = db.scalar(select(User).where(User.username == payload.username))
    if target is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="user not found")
    existing = db.get(ConversationMember, (group_id, target.id))
    if existing is not None:
        return _member_response(db, existing)
    membership = ConversationMember(conversation_id=group_id, user_id=target.id)
    db.add(membership)
    db.add(GroupMemberRole(conversation_id=group_id, user_id=target.id, role="member"))
    touch_group(conversation, profile)
    db.add_all([conversation, profile])
    db.commit()
    db.refresh(membership)
    return _member_response(db, membership)


@router.patch("/groups/{group_id}/members/{member_id}/role", response_model=GroupMemberResponse)
def update_group_member_role(
    group_id: str,
    member_id: str,
    payload: UpdateGroupRoleRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> GroupMemberResponse:
    require_role(db, group_id, user.id, "admin")
    membership = db.get(ConversationMember, (group_id, member_id))
    if membership is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="group member not found")
    role_row = db.get(GroupMemberRole, (group_id, member_id))
    current_role = role_row.role if role_row is not None else "member"
    if current_role == "admin" and payload.role != "admin" and admin_count(db, group_id) <= 1:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="group must keep at least one admin")
    if role_row is None:
        role_row = GroupMemberRole(conversation_id=group_id, user_id=member_id, role=payload.role)
    else:
        role_row.role = payload.role
    db.add(role_row)
    db.commit()
    return _member_response(db, membership)


@router.delete("/groups/{group_id}/members/{member_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_group_member(
    group_id: str,
    member_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> None:
    actor_role = require_group_member(db, group_id, user.id)
    membership = db.get(ConversationMember, (group_id, member_id))
    if membership is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="group member not found")
    target_role = member_role(db, group_id, member_id) or "member"

    if member_id == user.id:
        if target_role == "admin" and admin_count(db, group_id) <= 1:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="last admin cannot leave group")
    elif not can_remove(actor_role, target_role):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="cannot remove this group member")

    role_row = db.get(GroupMemberRole, (group_id, member_id))
    if role_row is not None:
        db.delete(role_row)
    db.delete(membership)
    conversation, profile = require_group(db, group_id)
    touch_group(conversation, profile)
    db.add_all([conversation, profile])
    db.commit()
