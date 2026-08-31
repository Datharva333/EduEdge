"""Versioned AI endpoints exposed to the Flutter application.

The backend owns lesson identity and maps a lesson id to the AI engine's
source filename. The Flutter app never needs to know AI-engine file paths.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.ai_bridge.client import AIEngineClient, AIEngineError
from app.ai_bridge.schemas import SummarizeRequest as AISummarizeRequest
from app.database.session import get_db
from app.repositories.lesson_repository import LessonRepository
from app.schemas.ai import (
    AIHealthResponse,
    SummarizeLessonRequest,
    SummarizeLessonResponse,
)

router = APIRouter()


@router.get("/health", response_model=AIHealthResponse)
def ai_health() -> AIHealthResponse:
    """Check that the backend can actually reach the local AI engine."""
    client = AIEngineClient(timeout_seconds=5.0)
    try:
        result = client.health()
    except AIEngineError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=exc.detail or "AI engine is unavailable",
        ) from exc
    finally:
        client.close()

    return AIHealthResponse(status=result.status)


@router.post("/summarize", response_model=SummarizeLessonResponse)
def summarize_lesson(
    payload: SummarizeLessonRequest,
    db: Session = Depends(get_db),
) -> SummarizeLessonResponse:
    """Generate a grounded summary for a backend lesson."""
    lesson = LessonRepository(db).get_by_id(payload.lesson_id)
    if lesson is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found",
        )

    client = AIEngineClient()
    try:
        result = client.summarize(
            AISummarizeRequest(
                filename=lesson.source_filename,
                topic=payload.topic,
            )
        )
    except AIEngineError as exc:
        # A missing source file is a content/configuration problem, while an
        # unreachable process is an availability problem. Preserve that
        # distinction for the app and for debugging.
        if exc.status_code == 404:
            raise HTTPException(
                status_code=status.HTTP_424_FAILED_DEPENDENCY,
                detail=exc.detail or "AI content for this lesson is unavailable",
            ) from exc

        if exc.status_code is None:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=exc.detail or "AI engine is unavailable",
            ) from exc

        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=exc.detail or "AI engine failed to generate a summary",
        ) from exc
    finally:
        client.close()

    return SummarizeLessonResponse(summary=result.summary)
