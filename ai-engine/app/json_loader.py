"""Parses subject/module JSON files into flat 'parent' units.

Schema (adjust key names if yours differs):

{
  "subject": "Science", "chapter": "Motion",
  "sections": [
    {
      "section_title": "Equations of Motion",
      "subsections": [
        {
          "subsection_title": "Deriving v = u + at",
          "content_type": "worked_example",
          "text": "..."
        }
      ]
    }
  ]
}

`content_type` is optional. Recognized values: "prose" (default),
"worked_example", "formula", "definition". Anything else is treated as
"prose". This drives how chunk.py handles the text -- worked examples and
formula-heavy blocks are kept whole rather than semantically split, since
splitting mid-derivation or mid-formula does more harm than good.
"""

from app.text_normalize import normalize_math_notation

_KNOWN_CONTENT_TYPES = {"prose", "worked_example", "formula", "definition"}


def _resolve_content_type(raw) -> str:
    return raw if raw in _KNOWN_CONTENT_TYPES else "prose"


def load_parent_units(json_data: dict) -> list[dict]:
    """Flattens a subject/module JSON file into a list of parent units.

    Returns:
        List of dicts: {"text": str, "content_type": str, "metadata": {...}}.
    """
    subject = json_data.get("subject", "")
    chapter = json_data.get("chapter", "")
    units: list[dict] = []

    for section in json_data.get("sections", []):
        section_title = section.get("section_title", "")
        subsections = section.get("subsections")

        if subsections:
            for sub in subsections:
                text = normalize_math_notation(sub.get("text", "").strip())
                if not text:
                    continue
                units.append({
                    "text": text,
                    "content_type": _resolve_content_type(sub.get("content_type")),
                    "metadata": {
                        "subject": subject,
                        "chapter": chapter,
                        "section": section_title,
                        "subsection": sub.get("subsection_title", ""),
                    },
                })
        else:
            text = normalize_math_notation(section.get("text", "").strip())
            if not text:
                continue
            units.append({
                "text": text,
                "content_type": _resolve_content_type(section.get("content_type")),
                "metadata": {
                    "subject": subject,
                    "chapter": chapter,
                    "section": section_title,
                    "subsection": "",
                },
            })

    return units