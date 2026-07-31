"""
Content pack routes — read-only listing/detail. Thin HTTP plumbing
only, per this project's convention (see routers/auth.py).

Note: devices do NOT use these to get content — they go through
POST /api/v1/sync (routers/sync.py), which returns deltas, not full
dumps. These endpoints exist for admin/debugging visibility (e.g. "is
my ingest script's output actually there") and could back a future
admin dashboard.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database.postgres import get_postgres_db
from app.repositories.content_pack_repository import ContentPackRepository
from app.schemas.content_pack import ContentPackResponse

router = APIRouter()


@router.get("/", response_model=list[ContentPackResponse])
def list_content_packs(db: Session = Depends(get_postgres_db)) -> list[ContentPackResponse]:
    return ContentPackRepository(db).list_all()


@router.get("/{pack_id}", response_model=ContentPackResponse)
def get_content_pack(pack_id: str, db: Session = Depends(get_postgres_db)) -> ContentPackResponse:
    pack = ContentPackRepository(db).get_by_id(pack_id)
    if pack is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Content pack not found")
    return pack
