"""
Lesson ORM model — lightweight, SQLite-only.

NOT part of the ContentPack -> Chapter -> ChunkMetadata pipeline
(see content_pack.py). That system is for the real offline-sync RAG
content, ingested via scripts/ingest_ncert_content.py and pulled by
devices through POST /api/v1/sync — it deliberately has no
"title"/"icon" fields and lives in Postgres.

This table exists only to back the simple GET /lessons and
GET /lessons/{id} endpoints the frontend's early demo screens call
(see routers/frontend_bridge.py). It's seeded with the same 3 lessons
his MockService already hardcodes, so his UI looks identical whether
it's reading mock data or this API. Safe to delete this file and its
router entirely once his lesson screens are wired to read real
content packs instead.
"""

from sqlalchemy import String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base


class Lesson(Base):
    __tablename__ = "lessons"

    # String id ("1", "2", "3") to match the ids the frontend's
    # MockService already uses — no change needed on his end.
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    subject: Mapped[str] = mapped_column(String(80), nullable=False)
    icon: Mapped[str] = mapped_column(String(10), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
