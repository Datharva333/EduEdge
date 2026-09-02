"""FastAPI service exposing the AI engine's chunking/embedding endpoints
to the backend, per backend/backend-ai-integration.MD and
backend/app/ai_bridge/schemas.py.

Run with: uvicorn api:app --reload --port 8001
"""

import hashlib
import json
import logging
import re
import time

from pathlib import Path

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from app.chunk import chunk_raw_text
from app.config import DATA_RAW_DIR, EMBED_MODEL_PATH
from app.embed import get_embed_model
from app.json_loader import load_parent_units
from app.llm import call_llm
from app.prompts import quiz_system_prompt, summarize_system_prompt
from app.rag import re_rank_cross_encoders, resolve_parent_context
from app.retrieve import query_collection

app = FastAPI(title="EduEdge AI Engine")
logger = logging.getLogger(__name__)


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

    model_config = {"protected_namespaces": ()}


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


def _retrieve_context(query: str, lesson_id: str | None = None) -> str:
    """Runs the existing retrieval -> rerank -> parent-resolution pipeline.

    TODO: `lesson_id` is currently unused -- Chroma metadata (see
    app/json_loader.py) only carries `subject`/`chapter`/`section`/
    `subsection` (free-text titles from the ingestion JSON), not an ID
    matching the backend's ContentPack/Chapter primary keys. Until
    ingestion writes a matching chapter/lesson ID into metadata, this
    searches the whole collection rather than scoping to one lesson.

    Raises:
        HTTPException: 404 if nothing relevant is found in the collection.
    """
    results = query_collection(query)
    documents = results.get("documents", [[]])[0]
    metadatas = results.get("metadatas", [[]])[0]

    if not documents:
        raise HTTPException(status_code=404, detail="No content found to answer from.")

    reranked_ids = re_rank_cross_encoders(query, documents)
    context, _parent_ids = resolve_parent_context(reranked_ids, metadatas)
    return context


def _load_source_context(filename: str) -> str:
    """Load one exact lesson JSON and return its complete normalized context.

    Chat and quiz deliberately use the backend-selected source filename rather
    than global Chroma retrieval. This guarantees that lesson 1 cannot retrieve
    content from lesson 2 or lesson 3 and also keeps the demo usable without
    rebuilding the vector database.
    """
    file_path = Path(DATA_RAW_DIR) / filename

    if not file_path.is_file():
        raise HTTPException(
            status_code=404,
            detail=f"No such file: {filename}",
        )

    try:
        with open(file_path, encoding="utf-8") as f:
            json_data = json.load(f)
    except json.JSONDecodeError as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid JSON in {filename}",
        ) from exc

    units = load_parent_units(json_data)

    if not units:
        raise HTTPException(
            status_code=404,
            detail="No content found in that file.",
        )

    return "\n\n".join(unit["text"] for unit in units)


# ── /ai/chat ────────────────────────────────────────────────────────
class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)
    filename: str = Field(min_length=1)


class ChatResponse(BaseModel):
    reply: str


@app.post("/ai/chat", response_model=ChatResponse)
def chat_endpoint(req: ChatRequest) -> ChatResponse:
    context = _load_source_context(req.filename)

    reply = "".join(
        call_llm(
            context=context,
            prompt=req.message,
            max_tokens=384,
        )
    ).strip()

    if not reply:
        raise HTTPException(
            status_code=502,
            detail="AI generated an empty reply.",
        )

    return ChatResponse(reply=reply)


# ── /ai/quiz ────────────────────────────────────────────────────────
class QuizRequest(BaseModel):
    filename: str = Field(min_length=1)
    num_questions: int = Field(default=5, ge=1, le=10)


class QuizQuestion(BaseModel):
    question: str
    options: list[str]
    correct_index: int


class QuizResponse(BaseModel):
    questions: list[QuizQuestion]


def _parse_quiz_json(raw: str) -> dict:
    text = raw.strip()

    # Small local models occasionally wrap otherwise-valid JSON in a
    # Markdown fence despite being instructed not to.
    text = re.sub(r"^```(?:json)?\s*", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\s*```$", "", text)

    start = text.find("{")
    end = text.rfind("}")

    if start == -1 or end == -1 or end < start:
        raise ValueError("No JSON object found in model output")

    return json.loads(text[start : end + 1])


@app.post("/ai/quiz", response_model=QuizResponse)
def quiz_endpoint(req: QuizRequest) -> QuizResponse:
    context = _load_source_context(req.filename)

    raw = "".join(
        call_llm(
            context=context,
            prompt=f"Generate exactly {req.num_questions} quiz questions.",
            system=quiz_system_prompt,
            max_tokens=512,
        )
    )

    try:
        parsed = _parse_quiz_json(raw)
        response = QuizResponse(**parsed)
    except (json.JSONDecodeError, TypeError, ValueError) as exc:
        logger.error("Quiz generation returned unparseable output: %s", raw)
        raise HTTPException(
            status_code=502,
            detail="Quiz generation failed to produce valid JSON.",
        ) from exc

    if len(response.questions) != req.num_questions:
        logger.warning(
            "Quiz requested %d questions but model returned %d.",
            req.num_questions,
            len(response.questions),
        )

    return response


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}

# ── /ai/summarize ───────────────────────────────────────────────────
class SummarizeRequest(BaseModel):
    # Path to the source JSON file, relative to DATA_RAW_DIR, e.g.
    # "science/motion.json". NOT the same as the backend's numeric
    # lessonId -- there's no mapping between the two yet (see the TODO
    # on _retrieve_context above). Until that mapping exists, the
    # backend needs to send the actual filename here.
    filename: str
    # Optional. If given, summarizes only the parts of the chapter
    # relevant to this topic (using cross-encoder reranking over the
    # chapter's own sections -- no Chroma/global retrieval involved,
    # since we already know exactly which file to look in). If omitted,
    # summarizes the whole chapter.
    topic: str | None = None


class SummarizeResponse(BaseModel):
    summary: str


@app.post("/ai/summarize", response_model=SummarizeResponse)
def summarize_endpoint(req: SummarizeRequest) -> SummarizeResponse:
    start = time.perf_counter()

    print(
        f"[SUMMARY] Starting: {req.filename}",
        flush=True,
    )

    file_path = Path(DATA_RAW_DIR) / req.filename

    if not file_path.is_file():
        raise HTTPException(
            status_code=404,
            detail=f"No such file: {req.filename}",
        )

    try:
        with open(file_path, encoding="utf-8") as f:
            json_data = json.load(f)
    except json.JSONDecodeError as e:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid JSON in {req.filename}",
        ) from e

    units = load_parent_units(json_data)

    print(
        f"[SUMMARY] Loaded {len(units)} content units",
        flush=True,
    )

    if not units:
        raise HTTPException(
            status_code=404,
            detail="No content found in that file.",
        )

    if req.topic:
        unit_texts = [unit["text"] for unit in units]
        reranked_ids = re_rank_cross_encoders(
            req.topic,
            unit_texts,
        )

        context = "\n\n".join(
            unit_texts[i] for i in reranked_ids
        )

        user_prompt = (
            f"Summarize what this chapter says about: {req.topic}"
        )
    else:
        context = "\n\n".join(
            unit["text"] for unit in units
        )

        user_prompt = "Summarize this chapter for a student."

    print(
        f"[SUMMARY] Context length: {len(context)} characters",
        flush=True,
    )

    llm_start = time.perf_counter()

    print(
        "[SUMMARY] Starting LLM generation...",
        flush=True,
    )

    summary = "".join(
        call_llm(
            context=context,
            prompt=user_prompt,
            system=summarize_system_prompt,
            max_tokens=256,
        )
    )

    print(
        f"[SUMMARY] LLM finished in "
        f"{time.perf_counter() - llm_start:.2f}s",
        flush=True,
    )

    print(
        f"[SUMMARY] Total request time: "
        f"{time.perf_counter() - start:.2f}s",
        flush=True,
    )

    return SummarizeResponse(summary=summary)