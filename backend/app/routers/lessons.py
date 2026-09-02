"""Versioned lesson API used by the Flutter application."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.repositories.lesson_repository import LessonRepository
from app.schemas.lesson import LessonResponse

router = APIRouter()


@router.get("", response_model=list[LessonResponse])
def list_lessons(db: Session = Depends(get_db)) -> list[LessonResponse]:
    """Return the current lesson catalogue from the backend database."""
    return LessonRepository(db).list_all()


@router.get("/{lesson_id}", response_model=LessonResponse)
def get_lesson(lesson_id: str, db: Session = Depends(get_db)) -> LessonResponse:
    """Return one lesson by its stable backend id."""
    lesson = LessonRepository(db).get_by_id(lesson_id)
    if lesson is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found",
        )
    return lesson
