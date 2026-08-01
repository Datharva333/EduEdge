"""
Postgres engine/session — the SYNC TARGET, not the request-facing DB.

No router or service should ever import PostgresSessionLocal directly
for handling a live request; only app/sync/sync_service.py touches
this, on its background interval. Keeping this boundary strict is
what keeps API latency independent of Postgres being reachable at all.
"""

from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.config.settings import settings
from app.database.base import Base

postgres_engine = create_engine(settings.postgres_database_url, pool_pre_ping=True)

PostgresSessionLocal = sessionmaker(bind=postgres_engine, autocommit=False, autoflush=False)


def get_postgres_db() -> Generator[Session, None, None]:
    """FastAPI dependency for the small set of routes that read/write
    Postgres directly — content packs only (see content_pack_repository.py
    docstring for why this table is the one exception to the
    SQLite-primary rule the rest of the app follows)."""
    db = PostgresSessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_postgres() -> None:
    """Creates tables in Postgres if they don't exist yet. Called at
    startup — wrapped in a try/except by main.py, since the app should
    still boot on SQLite alone even if Postgres isn't reachable yet."""
    Base.metadata.create_all(bind=postgres_engine)
