"""Auth routes — thin HTTP plumbing only, all logic delegated to AuthService."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.schemas.auth import TokenResponse, UserLoginRequest, UserRegisterRequest, UserResponse
from app.services.auth_service import AuthService

router = APIRouter()


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(payload: UserRegisterRequest, db: Session = Depends(get_db)) -> UserResponse:
    """Creates a new user in SQLite. Picked up by the background sync
    job and pushed to Postgres on the next sync interval."""
    service = AuthService(db)
    user = service.register(payload)
    return user


@router.post("/login", response_model=TokenResponse)
def login(payload: UserLoginRequest, db: Session = Depends(get_db)) -> TokenResponse:
    """Verifies credentials against SQLite and issues a JWT access token."""
    service = AuthService(db)
    user, token = service.login(payload)
    return TokenResponse(access_token=token, user=user)
