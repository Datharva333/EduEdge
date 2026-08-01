"""
Chunk versioning service.

Called from scripts/ingest_ncert_content.py, never from a live
request. Two responsibilities, kept deliberately separate:

1. mark_existing_packs_stale — when the AI engine reports it's now
   producing chunks under a NEW strategy_version, every pack ingested
   under an older version is flagged `is_stale` so you (or a
   dashboard) can see what needs re-ingesting. This does NOT change
   the pack's own chunking_strategy_version yet — that only happens
   once that specific pack is actually re-ingested.

2. apply_new_strategy_version — called per-pack, right after that
   pack has actually been re-chunked with the new strategy. Updates
   the pack's chunking_strategy_version and clears is_stale.

Splitting these matters: a large content library might not get every
pack re-ingested in one batch, so "stale" and "current version" need
to be tracked independently per pack.
"""

from app.models.content_pack import ContentPack
from app.repositories.content_pack_repository import ContentPackRepository


def mark_existing_packs_stale(repo: ContentPackRepository, new_strategy_version: int) -> list[ContentPack]:
    stale_packs = [
        pack for pack in repo.list_all() if pack.chunking_strategy_version < new_strategy_version
    ]
    for pack in stale_packs:
        repo.mark_stale(pack)
    return stale_packs


def apply_new_strategy_version(repo: ContentPackRepository, pack: ContentPack, new_strategy_version: int) -> None:
    repo.bump_chunking_strategy_version(pack, new_strategy_version)
