from __future__ import annotations

from datetime import UTC, datetime
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.business.models import BusinessProfile, CatalogItem
from app.business.schemas import (
    BusinessProfileResponse,
    BusinessProfileUpsertRequest,
    CatalogCreateRequest,
    CatalogItemResponse,
    CatalogUpdateRequest,
)
from app.business.service import require_business_mode, serialize_item, serialize_profile, validate_catalog_image
from app.chat.models import MessageAttachment
from app.core.config import settings
from app.identity.deps import get_current_user, get_db
from app.identity.models import User

router = APIRouter()


@router.put("/business/me/profile", response_model=BusinessProfileResponse)
def upsert_my_business_profile(
    payload: BusinessProfileUpsertRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> BusinessProfileResponse:
    require_business_mode(user)
    profile = db.get(BusinessProfile, user.id)
    now = datetime.now(UTC)
    if profile is None:
        profile = BusinessProfile(
            user_id=user.id,
            business_name=payload.business_name,
            category=payload.category,
            description=payload.description,
            address=payload.address,
            hours=payload.hours,
        )
    else:
        profile.business_name = payload.business_name
        profile.category = payload.category
        profile.description = payload.description
        profile.address = payload.address
        profile.hours = payload.hours
        profile.updated_at = now
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return serialize_profile(user, profile)


@router.get("/business/me/profile", response_model=BusinessProfileResponse)
def my_business_profile(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> BusinessProfileResponse:
    require_business_mode(user)
    profile = db.get(BusinessProfile, user.id)
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="business profile not configured")
    return serialize_profile(user, profile)


@router.get("/business/me/catalog", response_model=list[CatalogItemResponse])
def my_catalog(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[CatalogItemResponse]:
    require_business_mode(user)
    items = db.scalars(
        select(CatalogItem)
        .where(CatalogItem.owner_id == user.id, CatalogItem.is_active.is_(True))
        .order_by(CatalogItem.sort_order.asc(), CatalogItem.created_at.desc())
    ).all()
    return [serialize_item(item) for item in items]


@router.post("/business/catalog", response_model=CatalogItemResponse, status_code=status.HTTP_201_CREATED)
def create_catalog_item(
    payload: CatalogCreateRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CatalogItemResponse:
    require_business_mode(user)
    if db.get(BusinessProfile, user.id) is None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="configure business profile before adding catalog items")
    validate_catalog_image(db, user.id, payload.image_attachment_id)
    item = CatalogItem(
        owner_id=user.id,
        kind=payload.kind,
        title=payload.title,
        description=payload.description,
        price_amount=payload.price_amount,
        currency=payload.currency,
        availability=payload.availability,
        stock_qty=payload.stock_qty if payload.kind == "product" else None,
        image_attachment_id=payload.image_attachment_id,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return serialize_item(item)


@router.patch("/business/catalog/{item_id}", response_model=CatalogItemResponse)
def update_catalog_item(
    item_id: str,
    payload: CatalogUpdateRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CatalogItemResponse:
    require_business_mode(user)
    item = db.get(CatalogItem, item_id)
    if item is None or item.owner_id != user.id or not item.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="catalog item not found")

    fields = payload.model_fields_set
    new_kind = payload.kind if "kind" in fields and payload.kind is not None else item.kind
    if new_kind == "service" and "stock_qty" in fields and payload.stock_qty is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="service catalog item cannot have stock quantity")

    if "kind" in fields and payload.kind is not None:
        item.kind = payload.kind
        if item.kind == "service":
            item.stock_qty = None
    if "title" in fields and payload.title is not None:
        item.title = payload.title
    if "description" in fields and payload.description is not None:
        item.description = payload.description
    if "price_amount" in fields:
        item.price_amount = payload.price_amount
    if "currency" in fields and payload.currency is not None:
        item.currency = payload.currency
    if "availability" in fields and payload.availability is not None:
        item.availability = payload.availability
    if "stock_qty" in fields and new_kind == "product":
        item.stock_qty = payload.stock_qty
    if payload.clear_image:
        item.image_attachment_id = None
    elif "image_attachment_id" in fields:
        validate_catalog_image(db, user.id, payload.image_attachment_id, current_item_id=item.id)
        item.image_attachment_id = payload.image_attachment_id
    item.updated_at = datetime.now(UTC)
    db.add(item)
    db.commit()
    db.refresh(item)
    return serialize_item(item)


@router.delete("/business/catalog/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_catalog_item(
    item_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> None:
    require_business_mode(user)
    item = db.get(CatalogItem, item_id)
    if item is None or item.owner_id != user.id or not item.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="catalog item not found")
    item.is_active = False
    item.image_attachment_id = None
    item.updated_at = datetime.now(UTC)
    db.add(item)
    db.commit()


@router.get("/business/catalog/{item_id}/image")
def catalog_item_image(
    item_id: str,
    viewer: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FileResponse:
    item = db.get(CatalogItem, item_id)
    if item is None or item.image_attachment_id is None or (not item.is_active and item.owner_id != viewer.id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="catalog image not found")
    attachment = db.get(MessageAttachment, item.image_attachment_id)
    if attachment is None or attachment.kind != "image" or attachment.status != "ready":
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="catalog image not found")
    file_path = Path(settings.uploads_dir) / attachment.storage_key
    if not file_path.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="catalog image content missing")
    return FileResponse(
        path=file_path,
        media_type=attachment.content_type,
        filename=attachment.file_name,
        headers={"X-Content-Type-Options": "nosniff", "Cache-Control": "private, max-age=300"},
    )


@router.get("/business/{username}/profile", response_model=BusinessProfileResponse)
def public_business_profile(
    username: str,
    _viewer: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> BusinessProfileResponse:
    owner = db.scalar(select(User).where(User.username == username.strip().lower().lstrip("@")))
    if owner is None or not owner.business_mode:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="business profile not found")
    profile = db.get(BusinessProfile, owner.id)
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="business profile not found")
    return serialize_profile(owner, profile)


@router.get("/business/{username}/catalog", response_model=list[CatalogItemResponse])
def public_catalog(
    username: str,
    _viewer: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[CatalogItemResponse]:
    owner = db.scalar(select(User).where(User.username == username.strip().lower().lstrip("@")))
    if owner is None or not owner.business_mode or db.get(BusinessProfile, owner.id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="business profile not found")
    items = db.scalars(
        select(CatalogItem)
        .where(CatalogItem.owner_id == owner.id, CatalogItem.is_active.is_(True))
        .order_by(CatalogItem.sort_order.asc(), CatalogItem.created_at.desc())
    ).all()
    return [serialize_item(item) for item in items]
