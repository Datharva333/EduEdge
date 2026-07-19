"""
User repository — the ONLY place that runs raw queries against the
User table on the SQLite (primary) session. Services never construct
queries themselves; they call methods here.
"""

from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User


class UserRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_email(self, email: str) -> User | None:
        return self.db.scalar(select(User).where(User.email == email))

    def create(self, user: User) -> User:
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def get_unsynced(self, limit: int = 100) -> list[User]:
        """Rows not yet pushed to Postgres — picked up by the sync job."""
        stmt = select(User).where(User.is_synced.is_(False)).limit(limit)
        return list(self.db.scalars(stmt))

    def mark_synced(self, user: User) -> None:
        user.is_synced = True
        user.synced_at = datetime.utcnow()
        self.db.commit()
