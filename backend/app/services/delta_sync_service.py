"""
Delta sync service.

Given what a device says it already has for one content pack, decides
whether the device is up to date, needs only the changed chapters
(delta), or needs everything (full resync) — and assembles the actual
payload in each case.

The one behavioral rule that matters here: if the device's
chunking_strategy_version doesn't match the server's, we NEVER
attempt a delta. Old and new chunk boundaries for the same chapter
aren't comparable (token_start/token_end mean different things under
a different chunker), so mixing old and new chunks on a device would
silently corrupt its local retrieval index. A full resync is the only
safe move — this is the single change this file would need the day
your friend's chunker gets a semantic-chunking version bump.
"""

from app.repositories.content_pack_repository import ContentPackRepository
from app.schemas.content_pack import ChapterResponse, ContentPackResponse
from app.schemas.sync import DevicePackStatus, PackSyncResult
from app.services.translation_service import TranslationService


def compute_pack_sync(
    repo: ContentPackRepository,
    translation_service: TranslationService,
    device_status: DevicePackStatus,
) -> PackSyncResult:
    pack = repo.get_by_id(device_status.pack_id)
    if pack is None:
        return PackSyncResult(pack_id=device_status.pack_id, action="not_found")

    server_chapters = repo.get_chapters_for_pack(pack.id)

    # Rule above: strategy mismatch always wins, skip delta entirely.
    if device_status.chunking_strategy_version != pack.chunking_strategy_version:
        chapters = _build_chapter_payload(server_chapters, translation_service, device_status.language)
        return PackSyncResult(
            pack_id=pack.id,
            action="full_resync",
            content_pack=ContentPackResponse.model_validate(pack),
            chapters=chapters,
        )

    device_hashes = {c.chapter_id: c.raw_text_hash for c in device_status.chapters}
    changed_chapters = [
        chapter for chapter in server_chapters if device_hashes.get(chapter.id) != chapter.raw_text_hash
    ]

    if not changed_chapters:
        return PackSyncResult(pack_id=pack.id, action="up_to_date", content_pack=ContentPackResponse.model_validate(pack))

    chapters = _build_chapter_payload(changed_chapters, translation_service, device_status.language)
    return PackSyncResult(
        pack_id=pack.id,
        action="delta",
        content_pack=ContentPackResponse.model_validate(pack),
        chapters=chapters,
    )


def _build_chapter_payload(chapters, translation_service: TranslationService, language: str | None) -> list[ChapterResponse]:
    """Converts ORM Chapter rows into response schemas, overlaying
    translated text onto each chunk when the device requested a
    non-default language and a translation exists for it."""
    payload: list[ChapterResponse] = []
    for chapter in chapters:
        chunk_ids = [chunk.id for chunk in chapter.chunks]
        translations = translation_service.get_translations_map(chunk_ids, language) if language else {}

        chapter_response = ChapterResponse.model_validate(chapter)
        for chunk_response in chapter_response.chunks:
            chunk_response.translated_text = translations.get(chunk_response.id)
        payload.append(chapter_response)
    return payload
