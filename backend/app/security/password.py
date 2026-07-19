"""
Password hashing — never store or compare plaintext passwords.

Uses `bcrypt` directly rather than through passlib's CryptContext.
passlib 1.7.x's backend auto-detection is incompatible with bcrypt
4.x/5.x (it misdetects the backend and raises a spurious "password
cannot be longer than 72 bytes" error even for short passwords).
Calling bcrypt directly avoids that broken detection entirely and is
one less abstraction layer.
"""

import bcrypt

_BCRYPT_ROUNDS = 12


def hash_password(password: str) -> str:
    salt = bcrypt.gensalt(rounds=_BCRYPT_ROUNDS)
    hashed = bcrypt.hashpw(password.encode("utf-8"), salt)
    return hashed.decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))
