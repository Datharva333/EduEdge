"""
Sync orchestrator — the single entry point devices hit (POST
/api/v1/sync). Decides pack-level sync (via delta_sync_service) and
records progress upload, in one call.

Honest caveat on "one transaction": your friend's original note says
this should be "pack-level sync and progress-upload sync in one
transaction." Content lives in Postgres and progress lives in SQLite
(see the docstrings on ContentPack and Progress for why they're on
different engines) — there is no single database transaction that
can span both. What this DOES guarantee: content reads are read-only
(nothing to roll back), and all progress writes for this request are
wrapped in one SQLite transaction, so a failure partway through a
request's progress uploads doesn't leave a partial write behind.

NOT in scope of this file: this does not itself push Progress rows to
Postgres — that's still handled by the existing background loop in
app/sync/sync_service.py, extended in this change to also cover
Progress the same way it already covers User.
"""

from sqlalchemy.orm import Session

from app.models.progress import Progress
from app.repositories.content_pack_repository import ContentPackRepository
from app.repositories.progress_repository import ProgressRepository
from app.schemas.sync import SyncRequest, SyncResponse
from app.services.delta_sync_service import compute_pack_sync
from app.services.translation_service import TranslationService


def process_sync(sqlite_db: Session, postgres_db: Session, user_id: str, request: SyncRequest) -> SyncResponse:
    content_repo = ContentPackRepository(postgres_db)
    translation_service = TranslationService(postgres_db)

    pack_results = [
        compute_pack_sync(content_repo, translation_service, device_pack_status)
        for device_pack_status in request.packs
    ]

    progress_repo = ProgressRepository(sqlite_db)
    synced_count = 0
    try:
        for item in request.progress_updates:
            progress_repo.create(
                Progress(
                    user_id=user_id,
                    chapter_id=item.chapter_id,
                    chunk_id=item.chunk_id,
                    status=item.status,
                    score=item.score,
                )
            )
            synced_count += 1
    except Exception:
        sqlite_db.rollback()
        raise

    return SyncResponse(packs=pack_results, progress_synced_count=synced_count)
