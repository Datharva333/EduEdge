"""
Content pack ORM models: ContentPack -> Chapter -> ChunkMetadata.

These three tables mirror the AI engine's chunking output 1:1 on
purpose (see app/ai_bridge/schemas.py) — the ingestion script writes
whatever the AI engine's /chunk endpoint returns straight into these
rows with no transformation, so there's nothing to keep in sync
between "what the AI engine produced" and "what the backend stored".

Storage note: unlike User, these are NOT written through the SQLite
(primary) + background-sync-to-Postgres path. Content packs are
admin-ingested in bulk (via scripts/ingest_ncert_content.py) whenever
there's connectivity, not created by a live, possibly-offline device
request — so there's no need for the fast-local-write/eventually-sync
pattern User uses. Ingestion writes directly to Postgres, which is
the single source of truth for content; devices then pull content
through POST /api/v1/sync (see app/sync/sync_orchestrator.py), they
never write to these tables themselves.

UUID primary keys (not autoincrement ints) are used throughout the
project so IDs never collide across the two separately-writable
engines (SQLite primary + Postgres sync target) — same reasoning as
app/models/user.py.
"""

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base


class ContentPack(Base):
    """One subject+grade+language bundle, e.g. 'Science / Grade 8 / Hindi'."""

    __tablename__ = "content_packs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    subject: Mapped[str] = mapped_column(String(80), nullable=False)
    grade: Mapped[str] = mapped_column(String(20), nullable=False)
    language: Mapped[str] = mapped_column(String(20), nullable=False)

    # Bumped whenever the pack's content changes (new/edited chapters).
    pack_version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    # Bumped by chunk_versioning_service whenever ingest_ncert_content.py
    # runs with a DIFFERENT chunker implementation than last time. This is
    # what forces a full (not delta) resync on devices — see
    # delta_sync_service.py.
    chunking_strategy_version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    # SHA-256 over the pack's full raw content. Devices report the hash
    # they last synced; comparing it to this value is the cheap "does
    # anything need to sync at all" check before doing per-chapter work.
    content_hash: Mapped[str] = mapped_column(String(64), nullable=False)

    # Set by chunk_versioning_service when a newer chunking_strategy_version
    # is stamped, so admins/monitoring can see which packs are due a
    # re-ingest with the new chunker.
    is_stale: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    chapters: Mapped[list["Chapter"]] = relationship(
        back_populates="content_pack", cascade="all, delete-orphan", order_by="Chapter.order_index"
    )


class Chapter(Base):
    """One chapter within a ContentPack."""

    __tablename__ = "chapters"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    content_pack_id: Mapped[str] = mapped_column(String(36), ForeignKey("content_packs.id"), nullable=False)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    order_index: Mapped[int] = mapped_column(Integer, nullable=False)

    # Hash of this chapter's raw extracted text (pre-chunking). This is
    # the per-chapter granularity delta_sync_service actually diffs
    # against — finer than the whole-pack content_hash above.
    raw_text_hash: Mapped[str] = mapped_column(String(64), nullable=False)

    content_pack: Mapped["ContentPack"] = relationship(back_populates="chapters")
    chunks: Mapped[list["ChunkMetadata"]] = relationship(
        back_populates="chapter", cascade="all, delete-orphan", order_by="ChunkMetadata.token_start"
    )


class ChunkMetadata(Base):
    """One chunk produced by the AI engine's chunker for a chapter.

    parent_chunk_id is self-referential to support the AI engine's
    current parent-child recursive chunking strategy (a "child" chunk
    points back at its "parent" chunk); it's simply left null for any
    future flat chunking strategy.
    """

    __tablename__ = "chunk_metadata"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    chapter_id: Mapped[str] = mapped_column(String(36), ForeignKey("chapters.id"), nullable=False)
    parent_chunk_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("chunk_metadata.id"), nullable=True
    )

    text_hash: Mapped[str] = mapped_column(String(64), nullable=False)

    # The chunk's actual original-language text. This is the piece that
    # was missing before: the AI engine's /chunk response DOES include
    # full text per chunk (see ChunkItem.text in ai_bridge/schemas.py),
    # but ingestion was only persisting its hash. Devices need the real
    # text during full-resync/delta sync (schemas/content_pack.py
    # returns it as `text`), and translation_service needs it as the
    # source string to send to the AI engine's /translate endpoint —
    # neither works off a hash alone. The AI engine's own vector DB
    # (Chroma) also holds chunk text for retrieval, but that copy is
    # internal to his service and not reachable by this backend or by
    # an offline device, so this backend keeps its own copy.
    text: Mapped[str] = mapped_column(Text, nullable=False)

    token_start: Mapped[int] = mapped_column(Integer, nullable=False)
    token_end: Mapped[int] = mapped_column(Integer, nullable=False)

    # Which embedding model produced this chunk's vector. Not the vector
    # itself — embeddings live in the AI engine's own vector DB (Chroma),
    # never in this backend. This column exists purely so the backend
    # knows embeddings need regenerating if the AI engine reports a new
    # embedding_model_version during ingestion.
    embedding_model_version: Mapped[str] = mapped_column(String(50), nullable=False)

    # Only populated once the AI engine's chunker is semantic-aware;
    # null under the current parent-child recursive strategy. Reserved
    # now so the column exists before that ships (see ai_bridge/schemas.py).
    semantic_break_score: Mapped[float | None] = mapped_column(Float, nullable=True)

    chapter: Mapped["Chapter"] = relationship(back_populates="chunks")
