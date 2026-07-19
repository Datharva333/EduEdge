"""
Application entrypoint.

Startup sequence:
  1. Create SQLite tables (primary DB — always required).
  2. Try to create Postgres tables (sync target — optional at boot;
     the app must still run on SQLite alone if Postgres isn't up yet).
  3. Launch the background sync loop as an asyncio task.
"""

import asyncio
import logging

from fastapi import FastAPI

from app.core.constants import API_V1_PREFIX
from app.core.logging_config import configure_logging
from app.database.postgres import init_postgres
from app.database.session import init_sqlite
from app.routers import auth
from app.sync.sync_service import sync_loop

configure_logging()
logger = logging.getLogger(__name__)

app = FastAPI(
    title="EduEdge AI Backend",
    description="Backend API for EduEdge AI — offline-first AI learning platform.",
    version="1.0.0",
)


@app.on_event("startup")
async def on_startup() -> None:
    init_sqlite()
    logger.info("SQLite ready (primary database)")

    try:
        init_postgres()
        logger.info("PostgreSQL ready (sync target)")
    except Exception:
        logger.warning(
            "PostgreSQL not reachable at startup — API will still work "
            "on SQLite; sync will retry on its own interval.",
            exc_info=True,
        )

    asyncio.create_task(sync_loop())


@app.get("/health", tags=["Health"])
def health_check() -> dict[str, str]:
    return {"status": "ok"}


app.include_router(auth.router, prefix=f"{API_V1_PREFIX}/auth", tags=["Auth"])
