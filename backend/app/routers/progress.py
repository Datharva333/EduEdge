"""
Progress routes.

Two ways progress gets recorded in this system:
  1. Here — a single progress update, e.g. right after a student
     finishes one quiz while online.
  2. Bundled inside POST /api/v1/sync — a batch of progress updates
     that piled up while offline, uploaded together with content sync.

Both paths end up in the same table via the same repository, so
neither cares which one the client used.
"""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.models.progress import Progress
from app.models.user import User
from app.repositories.progress_repository import ProgressRepository
from app.schemas.progress import ProgressResponse, ProgressUploadItem
from app.security.dependencies import get_current_user

router = APIRouter()


@router.post("/", response_model=ProgressResponse, status_code=status.HTTP_201_CREATED)
def record_progress(
    payload: ProgressUploadItem,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ProgressResponse:
    repo = ProgressRepository(db)
    progress = repo.create(
        Progress(
            user_id=current_user.id,
            chapter_id=payload.chapter_id,
            chunk_id=payload.chunk_id,
            status=payload.status,
            score=payload.score,
        )
    )
    return progress


@router.get("/", response_model=list[ProgressResponse])
def list_my_progress(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[ProgressResponse]:
    return ProgressRepository(db).get_for_user(current_user.id)
