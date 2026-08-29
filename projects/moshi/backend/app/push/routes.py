from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.identity.deps import get_current_session, get_db
from app.identity.models import DeviceSession
from app.push.models import PushRegistration
from app.push.schemas import PushRegistrationRequest, PushRegistrationResponse

router = APIRouter()


@router.put("/devices/push", response_model=PushRegistrationResponse)
def register_push(
    payload: PushRegistrationRequest,
    session: DeviceSession = Depends(get_current_session),
    db: Session = Depends(get_db),
) -> PushRegistrationResponse:
    token = payload.token.strip()

    # A physical FCM token must belong to only one active MOSHI session. If the
    # same device signs into another account/session, move ownership instead of
    # risking notifications leaking to the old account.
    same_token = db.scalar(select(PushRegistration).where(PushRegistration.token == token))
    current = db.scalar(
        select(PushRegistration).where(PushRegistration.session_id == session.id)
    )
    if same_token is not None and same_token.session_id != session.id:
        db.delete(same_token)
        db.flush()
    if current is None:
        current = PushRegistration(
            session_id=session.id,
            user_id=session.user_id,
            provider=payload.provider,
            platform=payload.platform,
            token=token,
        )
    else:
        current.user_id = session.user_id
        current.provider = payload.provider
        current.platform = payload.platform
        current.token = token
    db.add(current)
    db.commit()
    return PushRegistrationResponse(provider=current.provider, platform=current.platform)


@router.delete("/devices/push", status_code=status.HTTP_204_NO_CONTENT)
def unregister_push(
    session: DeviceSession = Depends(get_current_session),
    db: Session = Depends(get_db),
) -> None:
    current = db.scalar(
        select(PushRegistration).where(PushRegistration.session_id == session.id)
    )
    if current is not None:
        db.delete(current)
        db.commit()
