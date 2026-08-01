"""
Progress ORM model.

Unlike ContentPack (admin-ingested, Postgres-only), Progress rows are
created constantly by students, often while offline — so this model
follows the SAME pattern as User: written to SQLite (primary) first
for an instant, network-independent response, then pushed to Postgres
by the background sync loop (see app/sync/sync_service.py, extended
in this file's companion service to also sync Progress).
"""

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base


class Progress(Base):
    """A student's status on one chapter or one chunk (e.g. a quiz)."""

    __tablename__ = "progress"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)

    # Exactly one of these two is set — chapter-level progress (e.g.
    # "read/unread") or chunk-level progress (e.g. a quiz tied to one
    # specific chunk). Enforced in schemas/progress.py, not at the DB
    # level, to keep this migration-friendly on SQLite.
    chapter_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("chapters.id"), nullable=True)
    chunk_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("chunk_metadata.id"), nullable=True)

    status: Mapped[str] = mapped_column(String(20), nullable=False)  # not_started | in_progress | completed
    score: Mapped[float | None] = mapped_column(Float, nullable=True)

    # ── Sync bookkeeping (SQLite side only) — identical role to User's ──
    is_synced: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    synced_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )
