"""Normalizes math/science notation in extracted text so it embeds and
chunks more reliably with a general-purpose text embedding model.

Unicode math symbols and inconsistent PDF-extraction artifacts (e.g.
superscript digits, root signs) often confuse both blingfire's sentence
splitter and the embedding model, since neither was trained heavily on
symbolic math notation. This converts common symbols to plain, spelled-out
ASCII equivalents so retrieval treats "x²" and "x^2" consistently.
"""

import re

_SUPERSCRIPT_MAP = {
    "⁰": "^0", "¹": "^1", "²": "^2", "³": "^3", "⁴": "^4",
    "⁵": "^5", "⁶": "^6", "⁷": "^7", "⁸": "^8", "⁹": "^9",
}
_SUBSCRIPT_MAP = {
    "₀": "_0", "₁": "_1", "₂": "_2", "₃": "_3", "₄": "_4",
    "₅": "_5", "₆": "_6", "₇": "_7", "₈": "_8", "₉": "_9",
}
_SYMBOL_MAP = {
    "√": "sqrt", "×": "*", "÷": "/", "≤": "<=", "≥": ">=",
    "≠": "!=", "≈": "~=", "∞": "infinity", "π": "pi",
    "°": " degrees", "½": "1/2", "¼": "1/4", "¾": "3/4",
    "∑": "sum", "∫": "integral", "∆": "delta", "µ": "micro",
}

_ALL_MAPS = {**_SUPERSCRIPT_MAP, **_SUBSCRIPT_MAP, **_SYMBOL_MAP}
_PATTERN = re.compile("|".join(re.escape(k) for k in _ALL_MAPS))


def normalize_math_notation(text: str) -> str:
    """Replaces Unicode math/science symbols with plain ASCII equivalents.

    Also collapses stray whitespace PDF extraction often introduces around
    exponents/subscripts (e.g. "x ^2" -> "x^2").
    """
    if not text:
        return text

    text = _PATTERN.sub(lambda m: _ALL_MAPS[m.group(0)], text)

    text = re.sub(r"\s*\^\s*(\d)", r"^\1", text)
    text = re.sub(r"\s*_\s*(\d)", r"_\1", text)
    text = re.sub(r"[ \t]{2,}", " ", text)

    return text.strip()