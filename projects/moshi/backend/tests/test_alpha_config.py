import pytest
from fastapi.testclient import TestClient

from app.core.config import DEV_JWT_SECRET, Settings
from app.main import app


def test_alpha_rejects_default_jwt_secret() -> None:
    with pytest.raises(ValueError, match="MOSHI_JWT_SECRET"):
        Settings(
            _env_file=None,
            environment="alpha",
            database_url="postgresql+psycopg://moshi:password@db:5432/moshi",
            jwt_secret=DEV_JWT_SECRET,
        )


def test_alpha_rejects_sqlite() -> None:
    with pytest.raises(ValueError, match="PostgreSQL"):
        Settings(
            _env_file=None,
            environment="alpha",
            database_url="sqlite:///./alpha.db",
            jwt_secret="x" * 48,
        )


def test_alpha_accepts_postgres_and_strong_secret() -> None:
    settings = Settings(
        _env_file=None,
        environment="alpha",
        database_url="postgresql+psycopg://moshi:password@db:5432/moshi",
        jwt_secret="x" * 48,
    )
    assert settings.environment == "alpha"


def test_readiness_probe_uses_database() -> None:
    with TestClient(app) as client:
        response = client.get("/ready")
        assert response.status_code == 200
        assert response.json()["status"] == "ready"
