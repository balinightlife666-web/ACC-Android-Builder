from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.core.config import settings


class Base(DeclarativeBase):
    pass


connect_args = {"check_same_thread": False} if settings.database_url.startswith("sqlite") else {}
engine = create_engine(settings.database_url, connect_args=connect_args)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def init_db() -> None:
    # Import models so SQLAlchemy knows the metadata before create_all.
    from app.identity import models  # noqa: F401
    from app.chat import models as chat_models  # noqa: F401
    from app.push import models as push_models  # noqa: F401
    from app.groups import models as group_models  # noqa: F401

    Base.metadata.create_all(bind=engine)
