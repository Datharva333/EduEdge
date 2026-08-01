"""
Progress repository — the ONLY place that runs raw queries against
the Progress table on the SQLite (primary) session. Mirrors
UserRepository's shape exactly — same sync bookkeeping pattern.
"""

from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.progress import Progress


class ProgressRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, progress: Progress) -> Progress:
        self.db.add(progress)
        self.db.commit()
        self.db.refresh(progress)
        return progress

    def get_by_id(self, progress_id: str) -> Progress | None:
        return self.db.scalar(select(Progress).where(Progress.id == progress_id))

    def get_for_user(self, user_id: str) -> list[Progress]:
        return list(self.db.scalars(select(Progress).where(Progress.user_id == user_id)))

    def get_unsynced(self, limit: int = 200) -> list[Progress]:
        """Rows not yet pushed to Postgres — picked up by the sync job."""
        stmt = select(Progress).where(Progress.is_synced.is_(False)).limit(limit)
        return list(self.db.scalars(stmt))

    def mark_synced(self, progress: Progress) -> None:
        progress.is_synced = True
        progress.synced_at = datetime.utcnow()
        self.db.commit()
