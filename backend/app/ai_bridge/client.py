"""HTTP client for the separate EduEdge AI engine service."""

import logging
from typing import TypeVar

import httpx
from pydantic import BaseModel

from app.ai_bridge.schemas import (
    CacheLookupRequest,
    CacheLookupResponse,
    ChatRequest,
    ChatResponse,
    ChunkRequest,
    ChunkResponse,
    EmbedRequest,
    EmbedResponse,
    HealthResponse,
    QuizRequest,
    QuizResponse,
    SummarizeRequest,
    SummarizeResponse,
    TranslateRequest,
    TranslateResponse,
)
from app.config.settings import settings

logger = logging.getLogger(__name__)

ResponseModel = TypeVar("ResponseModel", bound=BaseModel)


class AIEngineError(RuntimeError):
    """Structured failure returned by, or while contacting, the AI engine."""

    def __init__(
        self,
        message: str,
        *,
        status_code: int | None = None,
        detail: str | None = None,
    ) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.detail = detail or message


class AIEngineClient:
    def __init__(self, base_url: str | None = None, timeout_seconds: float = 300.0):
        self._client = httpx.Client(
            base_url=base_url or settings.ai_engine_base_url,
            timeout=timeout_seconds,
        )

    def health(self) -> HealthResponse:
        return self._get("/health", HealthResponse)

    def chunk(self, request: ChunkRequest) -> ChunkResponse:
        return self._post("/chunk", request, ChunkResponse)

    def embed(self, request: EmbedRequest) -> EmbedResponse:
        return self._post("/embed", request, EmbedResponse)

    def cache_lookup(self, request: CacheLookupRequest) -> CacheLookupResponse:
        return self._post("/cache/lookup", request, CacheLookupResponse)

    def translate(self, request: TranslateRequest) -> TranslateResponse:
        return self._post("/translate", request, TranslateResponse)

    def chat(self, request: ChatRequest) -> ChatResponse:
        return self._post("/ai/chat", request, ChatResponse)

    def quiz(self, request: QuizRequest) -> QuizResponse:
        return self._post("/ai/quiz", request, QuizResponse)

    def summarize(self, request: SummarizeRequest) -> SummarizeResponse:
        return self._post("/ai/summarize", request, SummarizeResponse)

    def _get(self, path: str, response_model: type[ResponseModel]) -> ResponseModel:
        try:
            response = self._client.get(path)
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise self._status_error(path, exc) from exc
        except httpx.RequestError as exc:
            logger.error("AI engine GET %s failed: %s", path, exc)
            raise AIEngineError(
                f"Could not reach AI engine at {path}",
                detail="Could not reach the AI engine process",
            ) from exc

        return response_model.model_validate(response.json())

    def _post(
        self,
        path: str,
        payload: BaseModel,
        response_model: type[ResponseModel],
    ) -> ResponseModel:
        try:
            response = self._client.post(path, json=payload.model_dump())
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise self._status_error(path, exc) from exc
        except httpx.RequestError as exc:
            logger.error("AI engine POST %s failed: %s", path, exc)
            raise AIEngineError(
                f"Could not reach AI engine at {path}",
                detail="Could not reach the AI engine process",
            ) from exc

        try:
            return response_model.model_validate(response.json())
        except Exception as exc:
            logger.error("AI engine returned an invalid response for %s", path)
            raise AIEngineError(
                f"Invalid AI engine response from {path}",
                status_code=response.status_code,
                detail="AI engine returned an invalid response",
            ) from exc

    @staticmethod
    def _status_error(path: str, exc: httpx.HTTPStatusError) -> AIEngineError:
        response = exc.response
        detail: str | None = None
        try:
            body = response.json()
            if isinstance(body, dict):
                raw_detail = body.get("detail")
                if raw_detail is not None:
                    detail = str(raw_detail)
        except ValueError:
            detail = None

        detail = detail or response.text or f"AI engine returned HTTP {response.status_code}"
        logger.error(
            "AI engine call to %s returned HTTP %s: %s",
            path,
            response.status_code,
            detail,
        )
        return AIEngineError(
            f"AI engine call to {path} failed",
            status_code=response.status_code,
            detail=detail,
        )

    def close(self) -> None:
        self._client.close()
