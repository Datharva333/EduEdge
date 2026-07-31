"""
Translation service (this backend's equivalent of your friend's
indictrans_service.py).

Two things worth being explicit about:

1. This runs ONLY as an offline batch step (scripts/run_translation_batch.py),
   right after ingestion, matching your friend's note that translation
   happens "during sync windows only" — never live, on-request.

2. This backend does not run IndicTrans2 itself — that's a model,
   and this backend never runs models (same "no RAG logic" rule that
   keeps chunking/embeddings out of here too). Translation is
   requested from the AI engine over HTTP via ai_bridge/client.py,
   exactly like chunking and embedding are. If your friend's contract
   ends up exposing translation differently, only this file and
   ai_bridge/schemas.py's Translate* models need to change.
"""

import logging

from app.ai_bridge.client import AIEngineClient
from app.ai_bridge.schemas import TranslateRequest
from app.repositories.translation_repository import TranslationRepository

logger = logging.getLogger(__name__)


class TranslationService:
    def __init__(self, db, ai_client: AIEngineClient | None = None):
        self.repo = TranslationRepository(db)
        self.ai_client = ai_client or AIEngineClient()

    def translate_and_store(self, chunk_id: str, text: str, target_language: str) -> None:
        """Called once per (chunk, language) pair by the batch script.
        Failures are logged and skipped rather than raised — one bad
        chunk shouldn't abort an entire batch run."""
        try:
            result = self.ai_client.translate(TranslateRequest(text=text, target_language=target_language))
        except Exception:
            logger.warning("Translation failed for chunk %s -> %s", chunk_id, target_language, exc_info=True)
            return
        self.repo.upsert(chunk_id, target_language, result.translated_text)

    def get_translations_map(self, chunk_ids: list[str], language: str) -> dict[str, str]:
        """Used by delta_sync_service to overlay translated text onto
        a sync response. Returns {chunk_id: translated_text} — chunks
        with no stored translation for this language simply aren't
        in the dict, so callers fall back to original text."""
        rows = self.repo.get_for_chunks(chunk_ids, language)
        return {row.chunk_id: row.translated_text for row in rows}
