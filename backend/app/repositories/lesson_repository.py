"""
Lesson repository — the ONLY place that runs raw queries against the
Lesson table on the SQLite (primary) session.
"""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.lesson import Lesson


class LessonRepository:
    def __init__(self, db: Session):
        self.db = db

    def list_all(self) -> list[Lesson]:
        return list(self.db.scalars(select(Lesson)))

    def get_by_id(self, lesson_id: str) -> Lesson | None:
        return self.db.scalar(select(Lesson).where(Lesson.id == lesson_id))
