"""Versioned AI endpoints exposed to the Flutter application.

The backend owns lesson identity and converts lesson IDs into source filenames.
Flutter therefore never needs to know paths inside the AI engine.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.ai_bridge.client import AIEngineClient, AIEngineError
from app.ai_bridge.schemas import (
    ChatRequest as AIChatRequest,
    QuizRequest as AIQuizRequest,
    SummarizeRequest as AISummarizeRequest,
)
from app.database.session import get_db
from app.repositories.lesson_repository import LessonRepository
from app.schemas.ai import (
    AIHealthResponse,
    ChatLessonRequest,
    ChatLessonResponse,
    QuizLessonRequest,
    QuizLessonResponse,
    SummarizeLessonRequest,
    SummarizeLessonResponse,
)

router = APIRouter()


def _source_for_lesson(db: Session, lesson_id: str) -> str:
    lesson = LessonRepository(db).get_by_id(lesson_id)

    if lesson is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found",
        )

    if not lesson.source_filename:
        raise HTTPException(
            status_code=status.HTTP_424_FAILED_DEPENDENCY,
            detail="No AI source file is configured for this lesson",
        )

    return lesson.source_filename


def _raise_ai_error(exc: AIEngineError, feature: str) -> None:
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
        detail=exc.detail or f"AI engine failed to {feature}",
    ) from exc


@router.get("/health", response_model=AIHealthResponse)
def ai_health() -> AIHealthResponse:
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
    source_filename = _source_for_lesson(db, payload.lesson_id)

    client = AIEngineClient()

    try:
        result = client.summarize(
            AISummarizeRequest(
                filename=source_filename,
                topic=payload.topic,
            )
        )
    except AIEngineError as exc:
        _raise_ai_error(exc, "generate a summary")
        raise
    finally:
        client.close()

    return SummarizeLessonResponse(summary=result.summary)


@router.post("/chat", response_model=ChatLessonResponse)
def chat_lesson(
    payload: ChatLessonRequest,
    db: Session = Depends(get_db),
) -> ChatLessonResponse:
    source_filename = _source_for_lesson(db, payload.lesson_id)

    client = AIEngineClient()

    try:
        result = client.chat(
            AIChatRequest(
                filename=source_filename,
                message=payload.message,
            )
        )
    except AIEngineError as exc:
        _raise_ai_error(exc, "answer the question")
        raise
    finally:
        client.close()

    return ChatLessonResponse(reply=result.reply)


@router.post("/quiz", response_model=QuizLessonResponse)
def quiz_lesson(
    payload: QuizLessonRequest,
    db: Session = Depends(get_db),
) -> QuizLessonResponse:
    source_filename = _source_for_lesson(db, payload.lesson_id)

    client = AIEngineClient()

    try:
        result = client.quiz(
            AIQuizRequest(
                filename=source_filename,
                num_questions=payload.num_questions,
            )
        )
    except AIEngineError as exc:
        _raise_ai_error(exc, "generate the quiz")
        raise
    finally:
        client.close()

    return QuizLessonResponse(questions=result.questions)
