"""
Shared auth dependency.

Not present in the uploaded auth module — auth.py only issues
tokens, nothing yet consumes them to protect a route. Progress and
sync endpoints need to know WHICH user is uploading progress, so this
adds that missing piece: decode the bearer token, load the user,
reject if invalid/inactive.
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.security.jwt import decode_access_token

_bearer_scheme = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    try:
        payload = decode_access_token(credentials.credentials)
    except ValueError as exc:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token") from exc

    # create_access_token (security/jwt.py) sets subject=user.id, so
    # `sub` here is always the user's id, never their email.
    user = UserRepository(db).get_by_id(payload["sub"])
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "User not found")
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Account is disabled")
    return user
