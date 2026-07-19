"""
Primary (SQLite) database session.

This is the database every API request talks to directly — writes
here are instant, with no network round trip to Postgres. The
sync module reads FROM this same database on a background interval
and pushes new/changed rows into Postgres separately (see
app/database/postgres.py and app/sync/sync_service.py).
"""

from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.config.settings import settings
from app.database.base import Base

sqlite_engine = create_engine(
    settings.sqlite_database_url,
    # SQLite only allows the connecting thread to use a connection by
    # default; FastAPI's dependency system can hand sessions across
    # threads, so this flag relaxes that restriction safely for our
    # single-writer-at-a-time use case.
    connect_args={"check_same_thread": False},
)

SQLiteSessionLocal = sessionmaker(bind=sqlite_engine, autocommit=False, autoflush=False)


def get_db() -> Generator[Session, None, None]:
    """FastAPI dependency — one session per request, always closed after."""
    db = SQLiteSessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_sqlite() -> None:
    """Creates tables in SQLite if they don't exist yet. Called at startup."""
    Base.metadata.create_all(bind=sqlite_engine)
