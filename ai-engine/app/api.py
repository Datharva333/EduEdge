"""FastAPI service exposing the AI engine's chunking/embedding endpoints
to the backend, per backend/backend-ai-integration.MD and
backend/app/ai_bridge/schemas.py.

Run with: uvicorn api:app --reload --port 8001
"""

import hashlib

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from app.chunk import chunk_raw_text
from app.config import EMBED_MODEL_PATH
from app.embed import get_embed_model

app = FastAPI(title="EduEdge AI Engine")


# ── /chunk ──────────────────────────────────────────────────────────
class ChunkRequest(BaseModel):
    raw_text: str
    chapter_id: str
    strategy_version: int


class ChunkItem(BaseModel):
    text: str
    text_hash: str
    token_start: int
    token_end: int
    parent_chunk_index: int | None = None
    semantic_break_score: float | None = None


class ChunkResponse(BaseModel):
    chunks: list[ChunkItem]
    embedding_model_version: str


def _hash(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


@app.post("/chunk", response_model=ChunkResponse)
def chunk_endpoint(req: ChunkRequest) -> ChunkResponse:
    if req.strategy_version != 1:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported strategy_version {req.strategy_version}; only 1 is implemented.",
        )

    tokenizer = get_embed_model().tokenizer

    items: list[ChunkItem] = []

    parent_tokens = len(tokenizer.encode(req.raw_text, add_special_tokens=False))
    items.append(ChunkItem(
        text=req.raw_text,
        text_hash=_hash(req.raw_text),
        token_start=0,
        token_end=parent_tokens,
        parent_chunk_index=None,
        semantic_break_score=None,
    ))
    parent_index = 0

    children = chunk_raw_text(req.raw_text)
    cursor = 0
    for child_text in children:
        child_tokens = len(tokenizer.encode(child_text, add_special_tokens=False))
        items.append(ChunkItem(
            text=child_text,
            text_hash=_hash(child_text),
            token_start=cursor,
            token_end=cursor + child_tokens,
            parent_chunk_index=parent_index,
            semantic_break_score=None,
        ))
        cursor += child_tokens

    return ChunkResponse(chunks=items, embedding_model_version=EMBED_MODEL_PATH)


# ── /embed ──────────────────────────────────────────────────────────
class EmbedRequest(BaseModel):
    texts: list[str]


class EmbedResponse(BaseModel):
    model_version: str
    count: int


@app.post("/embed", response_model=EmbedResponse)
def embed_endpoint(req: EmbedRequest) -> EmbedResponse:
    model = get_embed_model()
    embeddings = model.encode(req.texts, convert_to_numpy=True)
    return EmbedResponse(model_version=EMBED_MODEL_PATH, count=len(embeddings))


# ── /cache/lookup ───────────────────────────────────────────────────
class CacheLookupRequest(BaseModel):
    query_hash: str


class CacheLookupResponse(BaseModel):
    hit: bool
    answer: str | None = None


@app.post("/cache/lookup", response_model=CacheLookupResponse)
def cache_lookup_endpoint(req: CacheLookupRequest) -> CacheLookupResponse:
    return CacheLookupResponse(hit=False, answer=None)


# ── /translate ──────────────────────────────────────────────────────
class TranslateRequest(BaseModel):
    text: str
    target_language: str


class TranslateResponse(BaseModel):
    translated_text: str


@app.post("/translate", response_model=TranslateResponse)
def translate_endpoint(req: TranslateRequest) -> TranslateResponse:
    raise HTTPException(status_code=501, detail="Translation not implemented yet.")


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}