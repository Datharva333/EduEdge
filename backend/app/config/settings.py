"""
Application configuration.

Single source of truth for env-driven config. Notably holds TWO
database URLs — SQLITE_DATABASE_URL (primary, request-facing) and
POSTGRES_DATABASE_URL (sync target) — since this build writes to
SQLite instantly and background-syncs to Postgres on an interval.
"""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    environment: str = "development"
    log_level: str = "INFO"

    secret_key: str
    jwt_secret: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 15

    sqlite_database_url: str = "sqlite:///./eduedge.db"
    postgres_database_url: str

    sync_enabled: bool = True
    sync_interval_seconds: int = 30

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )


@lru_cache
def get_settings() -> Settings:
    """Cached so .env is parsed/validated once per process."""
    return Settings()


settings = get_settings()
