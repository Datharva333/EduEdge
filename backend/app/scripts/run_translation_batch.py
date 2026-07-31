"""
Translation batch script — this backend's equivalent of the Django
`tasks.py`. There's no Celery/task queue in this project, so this is
just a plain script: run it manually (or as a deploy/cron step) right
after ingest_ncert_content.py, for each language you need to support.

    python -m app.scripts.run_translation_batch --language hi

Deliberately separate from ingestion — a content update shouldn't be
blocked on every target language finishing translation, and you may
want to add a new supported language later without re-ingesting.
"""

import argparse
import logging

from sqlalchemy import select

from app.ai_bridge.client import AIEngineClient
from app.database.postgres import PostgresSessionLocal
from app.models.content_pack import ChunkMetadata
from app.services.translation_service import TranslationService

logger = logging.getLogger(__name__)


def run(language: str) -> None:
    db = PostgresSessionLocal()
    ai_client = AIEngineClient()
    service = TranslationService(db, ai_client)

    try:
        chunks = list(db.scalars(select(ChunkMetadata)))
        for chunk in chunks:
            service.translate_and_store(chunk.id, chunk.text, language)
        logger.info("Translation batch complete for language=%s (%d chunks)", language, len(chunks))
    finally:
        ai_client.close()
        db.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    parser = argparse.ArgumentParser()
    parser.add_argument("--language", required=True, help="Target language code, e.g. hi, mr, ta")
    args = parser.parse_args()
    run(args.language)
