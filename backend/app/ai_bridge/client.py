"""
AI engine HTTP client.

This is the ONLY connection point between your backend and your
friend's AI engine repo — a plain HTTP client hitting his FastAPI
service. No RAG logic, no chunking logic, no model code lives here or
anywhere else in this backend; this file just serializes a request,
sends it, and deserializes the response.

Used by:
  - scripts/ingest_ncert_content.py  -> chunk(), embed()
  - app/services/translation_service.py -> translate()
  - app/routers/frontend_bridge.py -> summarize()
  - (cache_lookup() is wired up but unused until you decide whether
    any endpoint needs a live "ask a question" path — see the note in
    the last message of this conversation about on-device vs
    server-proxied Q&A.)
"""

import logging
from typing import TypeVar

import httpx
from pydantic import BaseModel

from app.ai_bridge.schemas import (
    CacheLookupRequest,
    CacheLookupResponse,
    ChunkRequest,
    ChunkResponse,
    EmbedRequest,
    EmbedResponse,
    SummarizeRequest,
    SummarizeResponse,
    TranslateRequest,
    TranslateResponse,
)
from app.config.settings import settings

logger = logging.getLogger(__name__)

ResponseModel = TypeVar("ResponseModel", bound=BaseModel)


class AIEngineError(RuntimeError):
    """Raised when the AI engine is unreachable or returns an error.
    Callers (ingestion script, translation service, frontend bridge)
    decide whether to retry, skip, or abort — this client never
    swallows failures."""


class AIEngineClient:
    def __init__(self, base_url: str | None = None, timeout_seconds: float = 120.0):
        self._client = httpx.Client(
            base_url=base_url or settings.ai_engine_base_url,
            timeout=timeout_seconds,
        )

    def chunk(self, request: ChunkRequest) -> ChunkResponse:
        return self._post("/chunk", request, ChunkResponse)

    def embed(self, request: EmbedRequest) -> EmbedResponse:
        return self._post("/embed", request, EmbedResponse)

    def cache_lookup(self, request: CacheLookupRequest) -> CacheLookupResponse:
        return self._post("/cache/lookup", request, CacheLookupResponse)

    def translate(self, request: TranslateRequest) -> TranslateResponse:
        return self._post("/translate", request, TranslateResponse)

    def summarize(self, request: SummarizeRequest) -> SummarizeResponse:
        return self._post("/ai/summarize", request, SummarizeResponse)

    def _post(self, path: str, payload: BaseModel, response_model: type[ResponseModel]) -> ResponseModel:
        try:
            response = self._client.post(path, json=payload.model_dump())
            response.raise_for_status()
        except httpx.HTTPError as exc:
            logger.error("AI engine call to %s failed: %s", path, exc)
            raise AIEngineError(f"AI engine call to {path} failed") from exc
        return response_model.model_validate(response.json())

    def close(self) -> None:
        self._client.close()