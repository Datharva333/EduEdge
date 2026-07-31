"""Request/response schemas for progress endpoints and sync uploads."""

from pydantic import BaseModel, Field, model_validator


class ProgressUploadItem(BaseModel):
    """One progress row a device is uploading, either as a direct API
    call (routers/progress.py) or bundled inside a sync request
    (schemas/sync.py)."""

    chapter_id: str | None = None
    chunk_id: str | None = None
    status: str = Field(pattern="^(not_started|in_progress|completed)$")
    score: float | None = Field(default=None, ge=0, le=100)

    @model_validator(mode="after")
    def exactly_one_target(self) -> "ProgressUploadItem":
        if bool(self.chapter_id) == bool(self.chunk_id):
            raise ValueError("Exactly one of chapter_id or chunk_id must be set")
        return self


class ProgressResponse(BaseModel):
    id: str
    chapter_id: str | None
    chunk_id: str | None
    status: str
    score: float | None

    model_config = {"from_attributes": True}
