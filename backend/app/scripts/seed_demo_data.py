"""
Seeds the SQLite (primary) database with:
  - the 3 lessons the frontend's MockService already hardcodes, so
    GET /lessons isn't empty
  - one test user, so the frontend can log in without going through
    POST /api/v1/auth/register first

    python -m app.scripts.seed_demo_data

Test login: email=student@eduedge.com  password=test1234
"""

import logging

from app.database.session import SQLiteSessionLocal, init_sqlite
from app.models.lesson import Lesson
from app.models.user import User
from app.security.password import hash_password

logger = logging.getLogger(__name__)

LESSONS = [
    {
        "id": "1",
        "title": "Introduction to Photosynthesis",
        "subject": "Biology",
        "icon": "🌿",
        "content": (
            "Photosynthesis is the process by which green plants convert "
            "sunlight into food. Plants absorb carbon dioxide from the air "
            "and water from the soil. Using energy from sunlight, they "
            "convert these into glucose and oxygen. The equation is: "
            "6CO2 + 6H2O + light → C6H12O6 + 6O2. Chlorophyll in the leaves "
            "captures the light energy needed for this process."
        ),
        # NOTE: no real matching file on the AI engine yet — this will
        # 404 from /ai/summarize until Navin adds a biology JSON file
        # under ai-engine/data/raw/. Swap in the real path then.
        "source_filename": "biology/photosynthesis.json",
    },
    {
        "id": "2",
        "title": "Is Matter Around Us Pure?",
        "subject": "Science",
        "icon": "⚡",
        "content": (
            "Matter around us can be classified as pure substances or "
            "mixtures. Mixtures can be homogeneous (like solutions) or "
            "heterogeneous (like suspensions and colloids). This chapter "
            "covers solutions, concentration, the Tyndall effect, and how "
            "elements and compounds differ from mixtures."
        ),
        # This is the ONE file that actually exists right now under
        # ai-engine/data/raw/, so use lesson "2" for end-to-end testing.
        "source_filename": "science/matter_around_us_pure.json",
    },
    {
        "id": "3",
        "title": "World War II Overview",
        "subject": "History",
        "icon": "📖",
        "content": (
            "World War II was a global conflict from 1939 to 1945. It "
            "involved most of the world's nations and was the deadliest "
            "conflict in history. The war began with Germany's invasion of "
            "Poland. Key events include the Battle of Britain, D-Day, and "
            "the atomic bombings of Hiroshima and Nagasaki."
        ),
        # Same caveat as lesson "1" — placeholder until real content exists.
        "source_filename": "history/world_war_2.json",
    },
]


def run() -> None:
    init_sqlite()
    db = SQLiteSessionLocal()
    try:
        # Upsert instead of "seed only when empty". During development the
        # lesson metadata and source_filename mappings evolve; silently keeping
        # stale rows makes the frontend appear broken even when the code is
        # correct. Re-running this script now makes SQLite match LESSONS.
        created = 0
        updated = 0
        for data in LESSONS:
            lesson = db.get(Lesson, data["id"])
            if lesson is None:
                db.add(Lesson(**data))
                created += 1
                continue

            changed = False
            for field, value in data.items():
                if getattr(lesson, field) != value:
                    setattr(lesson, field, value)
                    changed = True
            if changed:
                updated += 1

        logger.info(
            "Demo lessons synchronized: %d created, %d updated.",
            created,
            updated,
        )

        if not db.query(User).filter(User.email == "student@eduedge.com").first():
            db.add(
                User(
                    full_name="Student",
                    email="student@eduedge.com",
                    hashed_password=hash_password("test1234"),
                )
            )
            logger.info("Seeded test user: student@eduedge.com / test1234")
        else:
            logger.info("Test user already exists, skipping.")

        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    run()