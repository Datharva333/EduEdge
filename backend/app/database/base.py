"""Shared declarative base. Every model inherits from this — it's what
lets the SAME model class be created against both the SQLite engine
and the Postgres engine (see session.py and postgres.py)."""

from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass
