"""Public API schemas for AI-powered lesson tools."""

from pydantic import BaseModel, ConfigDict, Field


class SummarizeLessonRequest(BaseModel):
    """Request from the Flutter app to summarize a backend lesson."""

    lesson_id: str = Field(alias="lessonId")
    topic: str | None = None

    model_config = ConfigDict(populate_by_name=True)


class SummarizeLessonResponse(BaseModel):
    summary: str


class AIHealthResponse(BaseModel):
    status: str
