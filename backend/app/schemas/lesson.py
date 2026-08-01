from pydantic import BaseModel


class LessonResponse(BaseModel):
    id: str
    title: str
    subject: str
    icon: str
    content: str

    model_config = {"from_attributes": True}
