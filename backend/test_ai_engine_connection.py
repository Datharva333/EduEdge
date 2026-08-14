"""One-off script to prove backend -> AI engine connection works, without
needing PDF extraction wired up yet. Delete once real ingestion is ready.

Run from the backend/ folder, with both services already running:
    python -m test_ai_engine_connection
"""

import logging

from app.scripts.ingest_ncert_content import ingest_pack

logging.basicConfig(level=logging.INFO)

sample_chapters = [
    ("Photosynthesis", "Photosynthesis is the process by which green plants "
     "convert light energy into chemical energy. This occurs in the "
     "chloroplasts, using chlorophyll to absorb sunlight."),
]

ingest_pack(subject="Science", grade="10", language="en", chapters=sample_chapters)
