"""
Translation repository — the ONLY place that runs raw queries against
TranslatedChunk. Not in the originally sketched folder tree, but
added to stay consistent with this project's rule (see
user_repository.py's docstring) that services never construct
queries themselves.
"""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.translation import TranslatedChunk


class TranslationRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_for_chunks(self, chunk_ids: list[str], language: str) -> list[TranslatedChunk]:
        if not chunk_ids:
            return []
        stmt = select(TranslatedChunk).where(
            TranslatedChunk.chunk_id.in_(chunk_ids),
            TranslatedChunk.language == language,
        )
        return list(self.db.scalars(stmt))

    def upsert(self, chunk_id: str, language: str, translated_text: str) -> TranslatedChunk:
        existing = self.db.scalar(
            select(TranslatedChunk).where(
                TranslatedChunk.chunk_id == chunk_id, TranslatedChunk.language == language
            )
        )
        if existing:
            existing.translated_text = translated_text
            self.db.commit()
            self.db.refresh(existing)
            return existing

        row = TranslatedChunk(chunk_id=chunk_id, language=language, translated_text=translated_text)
        self.db.add(row)
        self.db.commit()
        self.db.refresh(row)
        return row
