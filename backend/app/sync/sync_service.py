"""
Background sync: SQLite (primary) -> Postgres (sync target).

Every request writes to SQLite instantly and returns immediately —
Postgres is never on the critical path of a request. This module
runs in the background, on an interval, and pushes any user rows
not yet marked `is_synced` into Postgres using an UPSERT keyed on
email (so re-running sync, or syncing an updated row, never creates
duplicates).

If Postgres is unreachable, a sync attempt simply fails, logs a
warning, and is retried on the next interval — it never affects the
SQLite-backed API.
"""

import asyncio
import logging

from sqlalchemy.dialects.postgresql import insert as pg_insert

from app.config.settings import settings
from app.database.postgres import PostgresSessionLocal
from app.database.session import SQLiteSessionLocal
from app.models.progress import Progress
from app.models.user import User
from app.repositories.progress_repository import ProgressRepository
from app.repositories.user_repository import UserRepository

logger = logging.getLogger(__name__)


def sync_users_once() -> int:
    """Pushes all currently-unsynced SQLite users into Postgres in one
    pass. Returns the number of rows synced (0 on failure)."""
    sqlite_db = SQLiteSessionLocal()
    postgres_db = PostgresSessionLocal()
    synced_count = 0
    try:
        repo = UserRepository(sqlite_db)
        pending_users = repo.get_unsynced()

        for user in pending_users:
            stmt = pg_insert(User).values(
                id=user.id,
                full_name=user.full_name,
                email=user.email,
                hashed_password=user.hashed_password,
                role=user.role,
                is_active=user.is_active,
                is_synced=True,
                created_at=user.created_at,
                updated_at=user.updated_at,
            )
            # ON CONFLICT (email) DO UPDATE — safe to re-run, and
            # handles a user record that changed since the last sync.
            stmt = stmt.on_conflict_do_update(
                index_elements=["email"],
                set_={
                    "full_name": stmt.excluded.full_name,
                    "hashed_password": stmt.excluded.hashed_password,
                    "role": stmt.excluded.role,
                    "is_active": stmt.excluded.is_active,
                    "updated_at": stmt.excluded.updated_at,
                },
            )
            postgres_db.execute(stmt)
            repo.mark_synced(user)
            synced_count += 1

        postgres_db.commit()
        if synced_count:
            logger.info("Synced %d user(s) to PostgreSQL", synced_count)
        return synced_count

    except Exception:
        postgres_db.rollback()
        logger.warning("User sync to PostgreSQL failed this cycle", exc_info=True)
        return 0
    finally:
        sqlite_db.close()
        postgres_db.close()


def sync_progress_once() -> int:
    """Same pattern as sync_users_once, for the Progress table —
    pushes unsynced rows into Postgres, upserted on id (progress rows
    are created once per attempt and never edited afterwards, so id
    is a safe conflict key, unlike User's email)."""
    sqlite_db = SQLiteSessionLocal()
    postgres_db = PostgresSessionLocal()
    synced_count = 0
    try:
        repo = ProgressRepository(sqlite_db)
        pending = repo.get_unsynced()

        for progress in pending:
            stmt = pg_insert(Progress).values(
                id=progress.id,
                user_id=progress.user_id,
                chapter_id=progress.chapter_id,
                chunk_id=progress.chunk_id,
                status=progress.status,
                score=progress.score,
                is_synced=True,
                created_at=progress.created_at,
                updated_at=progress.updated_at,
            )
            stmt = stmt.on_conflict_do_update(
                index_elements=["id"],
                set_={
                    "status": stmt.excluded.status,
                    "score": stmt.excluded.score,
                    "updated_at": stmt.excluded.updated_at,
                },
            )
            postgres_db.execute(stmt)
            repo.mark_synced(progress)
            synced_count += 1

        postgres_db.commit()
        if synced_count:
            logger.info("Synced %d progress row(s) to PostgreSQL", synced_count)
        return synced_count

    except Exception:
        postgres_db.rollback()
        logger.warning("Progress sync to PostgreSQL failed this cycle", exc_info=True)
        return 0
    finally:
        sqlite_db.close()
        postgres_db.close()


async def sync_loop() -> None:
    """Started once at app startup (see main.py). Runs for the life of
    the process, syncing on a fixed interval. Uses asyncio.to_thread
    so the blocking DB calls never stall the event loop / API requests."""
    if not settings.sync_enabled:
        logger.info("Sync to PostgreSQL is disabled (SYNC_ENABLED=false)")
        return

    while True:
        await asyncio.sleep(settings.sync_interval_seconds)
        await asyncio.to_thread(sync_users_once)
        await asyncio.to_thread(sync_progress_once)
