"""Public API schemas for AI-powered lesson tools."""

from pydantic import BaseModel, ConfigDict, Field


class SummarizeLessonRequest(BaseModel):
    """Request from Flutter to summarize one backend-owned lesson."""

    lesson_id: str = Field(alias="lessonId")
    topic: str | None = None

    model_config = ConfigDict(populate_by_name=True)


class SummarizeLessonResponse(BaseModel):
    summary: str


class ChatLessonRequest(BaseModel):
    """Request from Flutter to ask a question about one lesson."""

    lesson_id: str = Field(alias="lessonId")
    message: str = Field(min_length=1, max_length=4000)

    model_config = ConfigDict(populate_by_name=True)


class ChatLessonResponse(BaseModel):
    reply: str


class QuizLessonRequest(BaseModel):
    """Request from Flutter to generate a quiz for one lesson."""

    lesson_id: str = Field(alias="lessonId")
    num_questions: int = Field(default=5, ge=1, le=10)

    model_config = ConfigDict(populate_by_name=True)


class QuizQuestionResponse(BaseModel):
    question: str
    options: list[str]
    correct_index: int


class QuizLessonResponse(BaseModel):
    questions: list[QuizQuestionResponse]


class AIHealthResponse(BaseModel):
    status: str
