from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


DEV_JWT_SECRET = "moshi-development-only-secret-change-now-2026"


class Settings(BaseSettings):
    app_name: str = "MOSHI API"
    environment: str = "development"
    api_prefix: str = "/v1"
    database_url: str = "sqlite:///./moshi.db"
    jwt_secret: str = DEV_JWT_SECRET
    jwt_algorithm: str = "HS256"
    access_token_minutes: int = 15
    refresh_token_days: int = 30
    uploads_dir: str = "./moshi_uploads"
    max_upload_bytes: int = 20 * 1024 * 1024
    # Optional. FCM credentials come from Google Application Default
    # Credentials (for example GOOGLE_APPLICATION_CREDENTIALS), never source code.
    fcm_project_id: str | None = None

    model_config = SettingsConfigDict(
        env_prefix="MOSHI_",
        env_file=".env",
        extra="ignore",
    )

    @model_validator(mode="after")
    def validate_runtime_safety(self) -> "Settings":
        environment = self.environment.strip().lower()
        hardened = environment in {"alpha", "alpha-smoke", "staging", "production"}
        if hardened and (self.jwt_secret == DEV_JWT_SECRET or len(self.jwt_secret) < 32):
            raise ValueError("MOSHI_JWT_SECRET must be a non-default secret of at least 32 characters")
        if environment in {"alpha", "staging", "production"} and self.database_url.startswith("sqlite"):
            raise ValueError("MOSHI_DATABASE_URL must use PostgreSQL for alpha/staging/production")
        return self


settings = Settings()
