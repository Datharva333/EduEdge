"""
Response shapes for app/routers/frontend_bridge.py.

Deliberately separate from schemas/auth.py's TokenResponse (which
returns access_token/token_type/full UserResponse) — the frontend's
early demo screens expect a smaller shape: { token, user: { name } }.
This file exists so that contract doesn't leak into or distort the
real UserResponse/TokenResponse used by /api/v1/auth.
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


class SummarizeResponse(BaseModel):
    summary: str
