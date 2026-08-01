"""
Sync route — the single endpoint the Flutter app calls to both pull
content updates and push queued progress, in one request. Requires
auth so progress uploads are attributed to the right user.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.postgres import get_postgres_db
from app.database.session import get_db
from app.models.user import User
from app.schemas.sync import SyncRequest, SyncResponse
from app.security.dependencies import get_current_user
from app.sync.sync_orchestrator import process_sync

router = APIRouter()


@router.post("/", response_model=SyncResponse)
def sync(
    payload: SyncRequest,
    current_user: User = Depends(get_current_user),
    sqlite_db: Session = Depends(get_db),
    postgres_db: Session = Depends(get_postgres_db),
) -> SyncResponse:
    return process_sync(sqlite_db, postgres_db, current_user.id, payload)
