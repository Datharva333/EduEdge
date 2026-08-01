"""
Ingestion script — this backend's equivalent of the Django
management command `ingest_ncert_content.py`.

Run manually (or from a deploy step) whenever there's new/updated
NCERT content to add:

    python -m app.scripts.ingest_ncert_content

What it does, in order:
  1. Reads raw chapter text (you supply the PDF-to-text extraction —
     that part is not defined by your friend's spec, so it's stubbed
     as `extract_raw_text` below; wire it to whatever PDF reader
     you're using).
  2. Sends each chapter's raw text to the AI engine's /chunk endpoint.
  3. Writes the resulting Chapter + ChunkMetadata rows into Postgres.
  4. Stamps the pack's chunking_strategy_version and content_hash.

CURRENT_CHUNKING_STRATEGY_VERSION is the one manual knob you turn:
bump it by hand in this file whenever your friend tells you he's
shipped a different chunker (e.g. semantic chunking). Everything
else — forcing full resyncs, marking old packs stale — follows
automatically from that one number, via chunk_versioning_service and
delta_sync_service.
"""

import hashlib
import logging

from app.ai_bridge.client import AIEngineClient
from app.ai_bridge.schemas import ChunkRequest
from app.database.postgres import PostgresSessionLocal
from app.models.content_pack import Chapter, ChunkMetadata, ContentPack
from app.repositories.content_pack_repository import ContentPackRepository
from app.services.chunk_versioning_service import apply_new_strategy_version, mark_existing_packs_stale

logger = logging.getLogger(__name__)

# Bump this by hand whenever the AI engine ships a new chunker
# implementation (e.g. 1 = parent-child recursive, 2 = semantic).
CURRENT_CHUNKING_STRATEGY_VERSION = 1


def extract_raw_text(pdf_path: str) -> str:
    """Stub — plug in your actual PDF text extraction here (e.g.
    pypdf, pdfplumber). Not specified in the AI engine handoff doc,
    so left as a clear seam rather than guessed at."""
    raise NotImplementedError("Wire this up to your PDF extraction pipeline")


def ingest_chapter(
    repo: ContentPackRepository,
    ai_client: AIEngineClient,
    pack: ContentPack,
    chapter_title: str,
    order_index: int,
    raw_text: str,
) -> Chapter:
    raw_text_hash = hashlib.sha256(raw_text.encode("utf-8")).hexdigest()

    chapter = repo.add_chapter(
        Chapter(
            content_pack_id=pack.id,
            title=chapter_title,
            order_index=order_index,
            raw_text_hash=raw_text_hash,
        )
    )

    chunk_response = ai_client.chunk(
        ChunkRequest(raw_text=raw_text, chapter_id=chapter.id, strategy_version=CURRENT_CHUNKING_STRATEGY_VERSION)
    )

    # First pass: insert every chunk, remembering each one's position
    # in the response so parent_chunk_index can be resolved to a real
    # ChunkMetadata.id on a second pass (parents may appear after
    # children in some chunkers, so this can't be done in one pass).
    inserted_chunks: list[ChunkMetadata] = []
    for item in chunk_response.chunks:
        chunk = repo.add_chunk(
            ChunkMetadata(
                chapter_id=chapter.id,
                text_hash=item.text_hash,
                text=item.text,
                token_start=item.token_start,
                token_end=item.token_end,
                embedding_model_version=chunk_response.embedding_model_version,
                semantic_break_score=item.semantic_break_score,
            )
        )
        inserted_chunks.append(chunk)

    for index, item in enumerate(chunk_response.chunks):
        if item.parent_chunk_index is not None:
            inserted_chunks[index].parent_chunk_id = inserted_chunks[item.parent_chunk_index].id
    repo.db.commit()

    return chapter


def ingest_pack(subject: str, grade: str, language: str, chapters: list[tuple[str, str]]) -> None:
    """chapters: list of (title, raw_text) tuples, in order."""
    db = PostgresSessionLocal()
    repo = ContentPackRepository(db)
    ai_client = AIEngineClient()

    try:
        mark_existing_packs_stale(repo, CURRENT_CHUNKING_STRATEGY_VERSION)

        pack = repo.get_by_subject_grade_language(subject, grade, language)
        combined_hash = hashlib.sha256("".join(text for _, text in chapters).encode("utf-8")).hexdigest()

        if pack is None:
            pack = repo.create_pack(
                ContentPack(
                    subject=subject,
                    grade=grade,
                    language=language,
                    chunking_strategy_version=CURRENT_CHUNKING_STRATEGY_VERSION,
                    content_hash=combined_hash,
                )
            )
        else:
            pack.pack_version += 1
            pack.content_hash = combined_hash
            db.commit()

        for order_index, (title, raw_text) in enumerate(chapters):
            ingest_chapter(repo, ai_client, pack, title, order_index, raw_text)

        apply_new_strategy_version(repo, pack, CURRENT_CHUNKING_STRATEGY_VERSION)
        logger.info("Ingested pack %s/%s/%s (%d chapters)", subject, grade, language, len(chapters))

    finally:
        ai_client.close()
        db.close()


if __name__ == "__main__":
    # Example invocation — replace with real chapter sourcing.
    logging.basicConfig(level=logging.INFO)
    raise SystemExit(
        "Fill in real (title, raw_text) chapter tuples and call ingest_pack(...) "
        "before running this script."
    )
