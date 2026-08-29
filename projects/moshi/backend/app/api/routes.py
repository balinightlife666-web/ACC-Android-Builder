from fastapi import APIRouter

from app.identity.routes import router as identity_router
from app.chat.routes import ALLOWED_FILE_TYPES, router as chat_router
from app.push.routes import router as push_router
from app.groups.routes import router as groups_router
from app.business.routes import router as business_router

from .models import SummaryRequest, SummaryResponse

VOICE_NOTE_CONTENT_TYPES = {"audio/mp4", "audio/aac", "audio/mpeg"}
ALLOWED_FILE_TYPES.update(VOICE_NOTE_CONTENT_TYPES)

router = APIRouter()
router.include_router(identity_router)
router.include_router(chat_router)
router.include_router(push_router)
router.include_router(groups_router)
router.include_router(business_router)


@router.get("/meta")
def meta() -> dict[str, object]:
    return {
        "product": "MOSHI",
        "phase": "business-catalog-core",
        "capabilities": [
            "identity",
            "auth",
            "chat",
            "groups",
            "push",
            "business",
            "business-profile",
            "business-catalog",
            "communities",
            "ai-summary",
        ],
    }


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
