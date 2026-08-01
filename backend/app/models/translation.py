"""
TranslatedChunk ORM model.

Translations are pre-computed and stored here — never generated live
at request time. app/services/translation_service.py (wrapping
IndicTrans2) is run as an offline batch step right after ingestion
(see scripts/run_translation_batch.py), so a device syncing content
gets ready-made translated text with zero added latency and zero
on-device translation work.
"""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base


class TranslatedChunk(Base):
    """One chunk's text translated into one target language."""

    __tablename__ = "translated_chunks"
    __table_args__ = (
        # A chunk can have at most one stored translation per language —
        # re-running the translation batch updates this row instead of
        # duplicating it (see translation_service.upsert_translation).
        UniqueConstraint("chunk_id", "language", name="uq_translated_chunks_chunk_language"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    chunk_id: Mapped[str] = mapped_column(String(36), ForeignKey("chunk_metadata.id"), nullable=False)
    language: Mapped[str] = mapped_column(String(20), nullable=False)
    translated_text: Mapped[str] = mapped_column(Text, nullable=False)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )
