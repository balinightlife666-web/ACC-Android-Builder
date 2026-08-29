from fastapi import APIRouter

from app.identity.routes import router as identity_router
from app.chat.routes import ALLOWED_FILE_TYPES, router as chat_router

from .models import (
    CatalogItemPreview,
    CatalogKind,
    SummaryRequest,
    SummaryResponse,
)

VOICE_NOTE_CONTENT_TYPES = {"audio/mp4", "audio/aac", "audio/mpeg"}
ALLOWED_FILE_TYPES.update(VOICE_NOTE_CONTENT_TYPES)

router = APIRouter()
router.include_router(identity_router)
router.include_router(chat_router)


@router.get("/meta")
def meta() -> dict[str, object]:
    return {
        "product": "MOSHI",
        "phase": "chat-core",
        "capabilities": ["identity", "auth", "chat", "communities", "business", "ai-summary"],
    }


@router.get("/business/catalog/preview", response_model=list[CatalogItemPreview])
def catalog_preview() -> list[CatalogItemPreview]:
    return [
        CatalogItemPreview(
            id="demo-service-1",
            title="Example Service",
            kind=CatalogKind.service,
            price=500_000,
        ),
        CatalogItemPreview(
            id="demo-product-1",
            title="Example Product",
            kind=CatalogKind.product,
            price=125_000,
        ),
    ]


@router.post("/ai/summary", response_model=SummaryResponse)
def summarize(payload: SummaryRequest) -> SummaryResponse:
    # Contract placeholder. Real AI integration is deliberately deferred until
    # message persistence, authorization and privacy boundaries are implemented.
    return SummaryResponse(
        conversation_id=payload.conversation_id,
        summary="AI summary integration is not enabled in the foundation build.",
        key_points=[],
        decisions=[],
        action_items=[],
        source_message_ids=payload.message_ids,
    )
