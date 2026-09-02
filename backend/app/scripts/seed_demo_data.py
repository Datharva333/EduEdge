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
        "title": "Quadratic Equations",
        "subject": "Mathematics",
        "icon": "📐",
        "content": (
            "A quadratic equation is an equation of degree two, usually written "
            "as ax² + bx + c = 0 where a is not zero. The discriminant "
            "b² - 4ac determines the nature of its roots, and the roots can be "
            "calculated using the quadratic formula."
        ),
        "source_filename": "maths/test_math_sample.json",
    },
    {
        "id": "2",
        "title": "Is Matter Around Us Pure?",
        "subject": "Science",
        "icon": "⚗️",
        "content": (
            "Matter around us can be classified as pure substances or mixtures. "
            "Mixtures may be homogeneous or heterogeneous. This chapter covers "
            "solutions, concentration, suspensions, colloids, the Tyndall effect, "
            "elements, compounds, and mixtures."
        ),
        "source_filename": "science/matter_around_us_pure.json",
    },
    {
        "id": "3",
        "title": "Grammar — Tenses",
        "subject": "English",
        "icon": "✏️",
        "content": (
            "Tenses are verb forms that show when an action or state occurs. "
            "English commonly groups tenses into present, past, and future, with "
            "forms used for habits, completed actions, continuing actions, and "
            "events expected to happen later."
        ),
        "source_filename": "english/tenses.json",
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