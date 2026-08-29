from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.business.models import BusinessProfile, CatalogItem
from app.business.schemas import BusinessProfileResponse, CatalogItemResponse
from app.chat.models import MessageAttachment
from app.chat.schemas import UserPreview
from app.identity.models import User


def require_business_mode(user: User) -> None:
    if not user.business_mode:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="enable Business Mode before managing a business profile or catalog",
        )


def serialize_profile(user: User, profile: BusinessProfile) -> BusinessProfileResponse:
    return BusinessProfileResponse(
        user=UserPreview.model_validate(user),
        business_name=profile.business_name,
        category=profile.category,
        description=profile.description,
        address=profile.address,
        hours=profile.hours,
        created_at=profile.created_at,
        updated_at=profile.updated_at,
    )


def serialize_item(item: CatalogItem) -> CatalogItemResponse:
    return CatalogItemResponse(
        id=item.id,
        owner_id=item.owner_id,
        kind=item.kind,
        title=item.title,
        description=item.description,
        price_amount=item.price_amount,
        currency=item.currency,
        availability=item.availability,
        stock_qty=item.stock_qty,
        image_path=f"/v1/business/catalog/{item.id}/image" if item.image_attachment_id else None,
        is_active=item.is_active,
        created_at=item.created_at,
        updated_at=item.updated_at,
    )


def validate_catalog_image(
    db: Session,
    owner_id: str,
    attachment_id: str | None,
    current_item_id: str | None = None,
) -> MessageAttachment | None:
    if attachment_id is None:
        return None
    attachment = db.get(MessageAttachment, attachment_id)
    if attachment is None or attachment.owner_id != owner_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="catalog image not found")
    if attachment.kind != "image" or attachment.status != "ready" or attachment.message_id is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="attachment is not available as a catalog image")
    query = select(CatalogItem).where(CatalogItem.image_attachment_id == attachment_id)
    if current_item_id is not None:
        query = query.where(CatalogItem.id != current_item_id)
    if db.scalar(query) is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="catalog image is already in use")
    return attachment
