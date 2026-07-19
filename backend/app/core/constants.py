"""App-wide constants — avoids magic strings scattered across files."""

from enum import Enum


class UserRole(str, Enum):
    STUDENT = "student"
    # TEACHER = "teacher"
    ADMIN = "admin"


API_V1_PREFIX = "/api/v1"
