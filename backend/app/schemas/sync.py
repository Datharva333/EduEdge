"""
Schemas for POST /api/v1/sync — the single endpoint devices hit to
both pull content updates and push progress in one round trip (see
app/sync/sync_orchestrator.py).
"""

from typing import Literal

from pydantic import BaseModel

from app.schemas.content_pack import ChapterResponse, ContentPackResponse
from app.schemas.progress import ProgressUploadItem


class DeviceChapterStatus(BaseModel):
    """What the device already has locally for one chapter — this is
    the actual granularity delta_sync_service diffs against."""

    chapter_id: str
    raw_text_hash: str


class DevicePackStatus(BaseModel):
    """What the device already has locally for one content pack."""

    pack_id: str
    chunking_strategy_version: int
    chapters: list[DeviceChapterStatus] = []
    # Language the device wants translated text in, if any. Falls back
    # to original chunk text when no translation exists for it.
    language: str | None = None


class SyncRequest(BaseModel):
    device_id: str
    packs: list[DevicePackStatus] = []
    progress_updates: list[ProgressUploadItem] = []


PackSyncAction = Literal["up_to_date", "delta", "full_resync", "not_found"]


class PackSyncResult(BaseModel):
    pack_id: str
    action: PackSyncAction
    content_pack: ContentPackResponse | None = None
    # Only the chapters that are new/changed (action="delta"), or ALL
    # chapters (action="full_resync"). Empty when action="up_to_date".
    chapters: list[ChapterResponse] = []


class SyncResponse(BaseModel):
    packs: list[PackSyncResult]
    progress_synced_count: int
