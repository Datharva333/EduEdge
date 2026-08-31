"""
Application entrypoint.

Startup sequence:
  1. Create SQLite tables (primary DB — always required).
  2. If sync is enabled, initialize PostgreSQL and launch the background
     SQLite -> PostgreSQL sync loop.
  3. If sync is disabled, run as a local SQLite-only API.
"""

import asyncio
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.constants import API_V1_PREFIX
from app.core.logging_config import configure_logging
from app.config.settings import settings
from app.database.postgres import init_postgres
from app.database.session import init_sqlite
from app.routers import ai, auth, content_packs, frontend_bridge, lessons, progress, sync
from app.sync.sync_service import sync_loop

configure_logging()
logger = logging.getLogger(__name__)

app = FastAPI(
    title="EduEdge AI Backend",
    description="Backend API for EduEdge AI — offline-first AI learning platform.",
    version="1.0.0",
)

# Dev-only: wide open so the Flutter app (emulator or a real device on
# the same Wi-Fi) can reach every route without CORS getting in the
# way. Lock this down to real origins before any public deployment.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def on_startup() -> None:
    init_sqlite()
    logger.info("SQLite ready (primary database)")

    if settings.sync_enabled:
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
    else:
        logger.info("PostgreSQL sync disabled for this environment")


@app.get("/health", tags=["Health"])
def health_check() -> dict[str, str]:
    return {"status": "ok"}


app.include_router(auth.router, prefix=f"{API_V1_PREFIX}/auth", tags=["Auth"])
app.include_router(content_packs.router, prefix=f"{API_V1_PREFIX}/content-packs", tags=["Content Packs"])
app.include_router(progress.router, prefix=f"{API_V1_PREFIX}/progress", tags=["Progress"])
app.include_router(sync.router, prefix=f"{API_V1_PREFIX}/sync", tags=["Sync"])
app.include_router(lessons.router, prefix=f"{API_V1_PREFIX}/lessons", tags=["Lessons"])
app.include_router(ai.router, prefix=f"{API_V1_PREFIX}/ai", tags=["AI"])

# Unprefixed routes matching the frontend's current demo contract
# (GET /lessons, POST /auth/login, POST /ai/summarize) — see
# routers/frontend_bridge.py for why these are kept separate from the
# real /api/v1 routes above.
app.include_router(frontend_bridge.router, tags=["Frontend Bridge (temporary)"])
