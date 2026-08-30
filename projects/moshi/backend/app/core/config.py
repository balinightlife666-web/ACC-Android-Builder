from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "MOSHI API"
    environment: str = "development"
    api_prefix: str = "/v1"
    database_url: str = "sqlite:///./moshi.db"
    jwt_secret: str = "moshi-development-only-secret-change-now-2026"
    jwt_algorithm: str = "HS256"
    access_token_minutes: int = 15
    refresh_token_days: int = 30

    model_config = SettingsConfigDict(
        env_prefix="MOSHI_",
        env_file=".env",
        extra="ignore",
    )


settings = Settings()
