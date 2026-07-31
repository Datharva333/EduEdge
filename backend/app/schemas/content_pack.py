"""
Content pack schemas — response shapes only. There's no
ContentPackCreateRequest here on purpose: packs are never created via
a device-facing API call, only by scripts/ingest_ncert_content.py
running directly against the repository. If you later add an admin
dashboard, its create/update endpoints would get their own request
schemas here.
"""

from pydantic import BaseModel


class ChunkMetadataResponse(BaseModel):
    id: str
    parent_chunk_id: str | None
    text: str
    text_hash: str
    token_start: int
    token_end: int
    embedding_model_version: str
    semantic_break_score: float | None
    # Populated only if a translation exists for the language the
    # requesting device asked for; None means "use the original text".
    translated_text: str | None = None

    model_config = {"from_attributes": True}


class ChapterResponse(BaseModel):
    id: str
    title: str
    order_index: int
    raw_text_hash: str
    chunks: list[ChunkMetadataResponse] = []

    model_config = {"from_attributes": True}


class ContentPackResponse(BaseModel):
    id: str
    subject: str
    grade: str
    language: str
    pack_version: int
    chunking_strategy_version: int
    content_hash: str

    model_config = {"from_attributes": True}
