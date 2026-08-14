"""Persistent store mapping parent_id -> full parent text + metadata.

Children (small, semantically-chunked pieces) are embedded and stored in
Chroma. Parents (larger section/subsection blocks from the source JSON) are
NOT embedded -- they're only looked up after retrieval + reranking, so the
LLM gets full surrounding context instead of an isolated child fragment.
"""

import json
import sqlite3
from pathlib import Path

from app.config import PARENT_STORE_PATH


def _get_connection() -> sqlite3.Connection:
    Path(PARENT_STORE_PATH).parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(PARENT_STORE_PATH)
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS parents (
            parent_id TEXT PRIMARY KEY,
            text TEXT NOT NULL,
            metadata TEXT NOT NULL
        )
        """
    )
    return conn


def save_parents(parents: dict[str, dict]) -> None:
    """Bulk insert. `parents` maps parent_id -> {'text': ..., 'metadata': {...}}."""
    conn = _get_connection()
    with conn:
        conn.executemany(
            "INSERT OR REPLACE INTO parents (parent_id, text, metadata) VALUES (?, ?, ?)",
            [(pid, p["text"], json.dumps(p["metadata"])) for pid, p in parents.items()],
        )
    conn.close()


def get_parents(parent_ids: list[str]) -> list[dict]:
    """Batch lookup. Dedupes parent_ids while preserving first-seen order."""
    seen = []
    for pid in parent_ids:
        if pid not in seen:
            seen.append(pid)
    if not seen:
        return []

    conn = _get_connection()
    placeholders = ",".join("?" * len(seen))
    rows = conn.execute(
        f"SELECT parent_id, text, metadata FROM parents WHERE parent_id IN ({placeholders})",
        seen,
    ).fetchall()
    conn.close()

    by_id = {r[0]: {"text": r[1], "metadata": json.loads(r[2])} for r in rows}
    return [by_id[pid] for pid in seen if pid in by_id]