"""
Response shapes for app/routers/frontend_bridge.py.

Deliberately separate from schemas/auth.py's TokenResponse (which
returns access_token/token_type/full UserResponse) — the frontend's
early demo screens expect a smaller shape: { token, user: { name } }.
This file exists so that contract doesn't leak into or distort the
real UserResponse/TokenResponse used by /api/v1/auth.

SummarizeRequest here is what the FLUTTER APP sends to this backend —
not to be confused with app.ai_bridge.schemas.SummarizeRequest, which
is what this backend sends on to the AI engine.
"""

from pydantic import BaseModel


class SimpleUser(BaseModel):
    name: str


class SimpleTokenResponse(BaseModel):
    token: str
    user: SimpleUser


class SummarizeRequest(BaseModel):
    lessonId: str | None = None
    text: str | None = None
    topic: str | None = None  # NEW — optional focus topic, forwarded to the AI engine


class SummarizeResponse(BaseModel):
    summary: str