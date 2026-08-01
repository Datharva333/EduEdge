"""
Frontend compatibility routes.

Your real API lives under /api/v1/* (see routers/auth.py,
content_packs.py) with production-shaped responses. Your frontend
teammate's current demo screens instead expect a smaller, unprefixed
contract:

    GET  /health          -> already exists at root in main.py
    POST /auth/login      -> { "token": "...", "user": { "name": "..." } }
    GET  /lessons          -> [ list of lessons ]
    GET  /lessons/{id}      -> single lesson
    POST /ai/summarize       -> { "summary": "..." } (hardcoded)

Rather than reshaping your real auth/content endpoints (and breaking
their production contract), this router adapts them: /auth/login
below calls the SAME AuthService.login() your real /api/v1/auth/login
uses, just re-shapes the response. Delete this whole file once his
app is updated to call the real /api/v1 endpoints directly.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.repositories.lesson_repository import LessonRepository
from app.schemas.auth import UserLoginRequest
from app.schemas.frontend_bridge import (
    SimpleTokenResponse,
    SimpleUser,
    SummarizeRequest,
    SummarizeResponse,
)
from app.schemas.lesson import LessonResponse
from app.services.auth_service import AuthService

router = APIRouter()


@router.post("/auth/login", response_model=SimpleTokenResponse)
def login(payload: UserLoginRequest, db: Session = Depends(get_db)) -> SimpleTokenResponse:
    service = AuthService(db)
    user, token = service.login(payload)  # raises 401 itself on bad credentials
    return SimpleTokenResponse(token=token, user=SimpleUser(name=user.full_name))


@router.get("/lessons", response_model=list[LessonResponse])
def list_lessons(db: Session = Depends(get_db)) -> list[LessonResponse]:
    return LessonRepository(db).list_all()


@router.get("/lessons/{lesson_id}", response_model=LessonResponse)
def get_lesson(lesson_id: str, db: Session = Depends(get_db)) -> LessonResponse:
    lesson = LessonRepository(db).get_by_id(lesson_id)
    if lesson is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Lesson not found")
    return lesson


@router.post("/ai/summarize", response_model=SummarizeResponse)
def summarize(payload: SummarizeRequest) -> SummarizeResponse:
    # Hardcoded per the contract your friend sent. Swap this for a real
    # call through app/ai_bridge/client.py once the AI engine exposes a
    # summarize-equivalent endpoint — this is the only place to change.
    return SummarizeResponse(
        summary=(
            "This is a placeholder AI-generated summary. Once the AI "
            "engine is connected, this will be a real summary of the "
            "lesson content."
        )
    )
