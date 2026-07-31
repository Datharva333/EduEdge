"""
Content pack repository — the ONLY place that runs raw queries
against ContentPack/Chapter/ChunkMetadata.

Deliberately takes a Postgres session, not the usual SQLite
`get_db()` session other repositories use — content packs are
admin-ingested straight into Postgres (see app/models/content_pack.py
for why) and read from there by the sync endpoint. Callers get a
session via app.database.postgres.get_postgres_db.
"""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.content_pack import Chapter, ChunkMetadata, ContentPack


class ContentPackRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, pack_id: str) -> ContentPack | None:
        return self.db.scalar(select(ContentPack).where(ContentPack.id == pack_id))

    def get_by_subject_grade_language(self, subject: str, grade: str, language: str) -> ContentPack | None:
        stmt = select(ContentPack).where(
            ContentPack.subject == subject,
            ContentPack.grade == grade,
            ContentPack.language == language,
        )
        return self.db.scalar(stmt)

    def list_all(self) -> list[ContentPack]:
        return list(self.db.scalars(select(ContentPack)))

    def create_pack(self, pack: ContentPack) -> ContentPack:
        self.db.add(pack)
        self.db.commit()
        self.db.refresh(pack)
        return pack

    def add_chapter(self, chapter: Chapter) -> Chapter:
        self.db.add(chapter)
        self.db.commit()
        self.db.refresh(chapter)
        return chapter

    def add_chunk(self, chunk: ChunkMetadata) -> ChunkMetadata:
        self.db.add(chunk)
        self.db.commit()
        self.db.refresh(chunk)
        return chunk

    def get_chapters_for_pack(self, pack_id: str) -> list[Chapter]:
        stmt = select(Chapter).where(Chapter.content_pack_id == pack_id).order_by(Chapter.order_index)
        return list(self.db.scalars(stmt))

    def mark_stale(self, pack: ContentPack) -> None:
        """Called by chunk_versioning_service when a new chunker ships —
        flags this pack as needing re-ingestion with the new strategy."""
        pack.is_stale = True
        self.db.commit()

    def bump_chunking_strategy_version(self, pack: ContentPack, new_version: int) -> None:
        pack.chunking_strategy_version = new_version
        pack.is_stale = False
        self.db.commit()
