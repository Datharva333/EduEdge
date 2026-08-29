"""
Request/response schemas for the AI engine's HTTP API.

These are the ONE place this backend encodes assumptions about the
AI engine's shape. If your teammate changes /chunk or /embed's
payload, this is the only file that should need editing — client.py,
the ingestion script, and every service that calls it just use these
models and never touch raw JSON directly.

IMPORTANT: these field names/types are a reasonable placeholder based
on the shared spec, not confirmed against his actual running service
yet. Get a real sample response from him and adjust this file before
running ingestion for real — see the note left in each class.
"""

from pydantic import BaseModel


# ── /chunk ──────────────────────────────────────────────────────────
class ChunkRequest(BaseModel):
    raw_text: str
    chapter_id: str
    # Which chunker implementation to use — lets the AI engine support
    # multiple strategies (current: parent-child recursive; future:
    # semantic) behind one endpoint, selected by version number.
    strategy_version: int


class ChunkItem(BaseModel):
    text: str
    text_hash: str
    token_start: int
    token_end: int
    # Index into this same response's chunk list, not a DB id — the
    # backend resolves this to a real ChunkMetadata.id after inserting
    # rows (see scripts/ingest_ncert_content.py).
    parent_chunk_index: int | None = None
    # Present only once the AI engine's chunker is semantic-aware.
    semantic_break_score: float | None = None


class ChunkResponse(BaseModel):
    chunks: list[ChunkItem]
    embedding_model_version: str


# ── /embed ──────────────────────────────────────────────────────────
class EmbedRequest(BaseModel):
    texts: list[str]


class EmbedResponse(BaseModel):
    # Embeddings themselves are NOT stored by this backend — they stay
    # in the AI engine's own vector DB (Chroma). This response is only
    # consulted for embedding_model_version bookkeeping during
    # ingestion; the vectors are discarded after the call.
    model_version: str
    count: int


# ── /cache/lookup ─────────────────────────────────────────────────
class CacheLookupRequest(BaseModel):
    query_hash: str


class CacheLookupResponse(BaseModel):
    # Stubbed permanently-false on his side until implemented — see
    # his spec. client.py's cache_lookup() always gets a well-formed
    # response either way, so callers never need a special case.
    hit: bool
    answer: str | None = None


# ── /translate (added to the contract for translation_service.py) ──
class TranslateRequest(BaseModel):
    text: str
    target_language: str


class TranslateResponse(BaseModel):
    translated_text: str


# ── /ai/summarize ────────────────────────────────────────────────────
# NOTE: this is the request/response shape for calling the AI ENGINE's
# /ai/summarize endpoint. It's a different class from
# app.schemas.frontend_bridge.SummarizeRequest, which is the shape the
# Flutter app sends TO this backend. Don't confuse the two — import
# this one with an alias in routers/frontend_bridge.py.
class SummarizeRequest(BaseModel):
    filename: str
    topic: str | None = None


class SummarizeResponse(BaseModel):
    summary: str