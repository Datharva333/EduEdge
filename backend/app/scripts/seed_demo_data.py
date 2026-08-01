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
    },
    {
        "id": "2",
        "title": "Newton's Laws of Motion",
        "subject": "Physics",
        "icon": "⚡",
        "content": (
            "Newton's three laws of motion form the foundation of classical "
            "mechanics. The first law states that an object stays at rest "
            "or in motion unless acted upon by a force. The second law "
            "states F=ma, force equals mass times acceleration. The third "
            "law states every action has an equal and opposite reaction."
        ),
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
    },
]


def run() -> None:
    init_sqlite()
    db = SQLiteSessionLocal()
    try:
        if db.query(Lesson).count() == 0:
            for data in LESSONS:
                db.add(Lesson(**data))
            logger.info("Seeded %d lessons.", len(LESSONS))
        else:
            logger.info("Lessons already exist, skipping.")

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
