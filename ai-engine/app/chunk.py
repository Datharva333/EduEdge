# """PDF loading and text chunking (unchanged from the original demo)."""

# import os
# import tempfile

# from langchain_community.document_loaders import PyMuPDFLoader
# from langchain_core.documents import Document
# from langchain_text_splitters import RecursiveCharacterTextSplitter
# from streamlit.runtime.uploaded_file_manager import UploadedFile

# from app.config import CHUNK_OVERLAP, CHUNK_SEPARATORS, CHUNK_SIZE


# def process_document(uploaded_file: UploadedFile) -> list[Document]:
#     """Processes an uploaded PDF file by converting it to text chunks.

#     Takes an uploaded PDF file, saves it temporarily, loads and splits the
#     content into text chunks using recursive character splitting.

#     Args:
#         uploaded_file: A Streamlit UploadedFile object containing the PDF file.

#     Returns:
#         A list of Document objects containing the chunked text from the PDF.

#     Raises:
#         IOError: If there are issues reading/writing the temporary file.
#     """
#     with tempfile.NamedTemporaryFile(
#         mode="wb",
#         suffix=".pdf",
#         delete=False,
#     ) as temp_file:
#         temp_file.write(uploaded_file.read())
#         temp_path = temp_file.name

#     loader = PyMuPDFLoader(temp_path)
#     docs = loader.load()

#     os.remove(temp_path)

#     text_splitter = RecursiveCharacterTextSplitter(
#         chunk_size=CHUNK_SIZE,
#         chunk_overlap=CHUNK_OVERLAP,
#         separators=CHUNK_SEPARATORS,
#     )

#     return text_splitter.split_documents(docs)
"""Semantic chunking: turns each parent unit's text into small,
topic-coherent 'child' chunks, linked back to their parent.

Pipeline per parent unit:
  1. Split into sentences with blingfire (accurate boundary detection).
  2. Embed each sentence (combined with a small neighbor window, for a
     more stable signal than embedding tiny sentences alone) using the
     same embedding model used for retrieval.
  3. Compute cosine distance between consecutive sentence embeddings.
  4. Wherever the distance spikes above a percentile threshold, that's a
     likely topic shift -> candidate breakpoint.
  5. Group sentences between breakpoints into a child chunk, respecting
     MIN/MAX token bounds (a long "coherent" run still gets split; a tiny
     run gets merged forward).

Parents are written to the ParentStore untouched. Only the children are
returned for embedding + upsert into Chroma, each carrying a `parent_id`
in its metadata.
"""

import uuid

import blingfire
import numpy as np
from langchain_core.documents import Document

from app.config import (
    BREAKPOINT_PERCENTILE,
    MAX_CHUNK_TOKENS,
    MIN_CHUNK_TOKENS,
    WINDOW_SIZE,
    NON_SEMANTIC_HARD_CAP_TOKENS,
)
from app.embed import get_embed_model
from app.json_loader import load_parent_units
from app import parent_store


def _count_tokens(text: str) -> int:
    """Uses the embedding model's own tokenizer, so chunk sizing matches
    what actually gets embedded/retrieved."""
    tokenizer = get_embed_model().tokenizer
    return len(tokenizer.encode(text, add_special_tokens=False))

def _paragraph_split_fallback(text: str) -> list[str]:
    """Splits on blank lines only -- last-resort fallback for
    worked_example/formula blocks that exceed NON_SEMANTIC_HARD_CAP_TOKENS.
    Never applies semantic breakpoint detection: splitting a derivation or
    formula mid-step is worse than one oversized chunk."""
    paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
    return paragraphs if paragraphs else [text]


def chunk_parent(parent_text: str, content_type: str = "prose") -> list[str]:
    """Splits one parent's text into children, using a strategy matched to
    its content_type.

    - "prose" / "definition": semantic chunking (blingfire + breakpoint
      detection), as before.
    - "worked_example" / "formula": kept as a single child whenever
      possible -- splitting mid-derivation or mid-formula breaks the LLM's
      ability to reproduce correct working. Only falls back to a
      blank-line paragraph split if the block is unusually long.
    """
    if content_type in ("worked_example", "formula"):
        if _count_tokens(parent_text) <= NON_SEMANTIC_HARD_CAP_TOKENS:
            return [parent_text]
        return _paragraph_split_fallback(parent_text)

    return semantic_chunk_parent(parent_text)

def _split_sentences(text: str) -> list[str]:
    raw = blingfire.text_to_sentences(text)
    return [s.strip() for s in raw.split("\n") if s.strip()]


def _windowed(sentences: list[str], window: int) -> list[str]:
    """Combines each sentence with `window` neighbors on each side before
    embedding, to reduce noise from very short sentences. Breakpoints are
    still recorded at the original sentence boundary."""
    combined = []
    for i in range(len(sentences)):
        start = max(0, i - window)
        end = min(len(sentences), i + window + 1)
        combined.append(" ".join(sentences[start:end]))
    return combined


def _cosine_distance(a: np.ndarray, b: np.ndarray) -> float:
    sim = np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-8)
    return 1.0 - float(sim)


def _semantic_breakpoints(sentences: list[str], embed_model) -> set[int]:
    """Returns sentence indices i such that there's a breakpoint between
    sentence i and sentence i+1."""
    if len(sentences) <= 1:
        return set()

    windowed_text = _windowed(sentences, WINDOW_SIZE)
    embeddings = embed_model.encode(windowed_text, convert_to_numpy=True)

    distances = [
        _cosine_distance(embeddings[i], embeddings[i + 1])
        for i in range(len(embeddings) - 1)
    ]
    if not distances:
        return set()

    threshold = np.percentile(distances, BREAKPOINT_PERCENTILE)
    return {i for i, d in enumerate(distances) if d > threshold}


def _group_into_children(sentences: list[str], breakpoints: set[int]) -> list[str]:
    """Groups sentences into child chunks at semantic breakpoints, while
    enforcing MIN/MAX token bounds per child."""
    children: list[str] = []
    current: list[str] = [sentences[0]]
    current_tokens = _count_tokens(sentences[0])

    for i in range(len(sentences) - 1):
        next_sentence = sentences[i + 1]
        next_tokens = _count_tokens(next_sentence)

        at_breakpoint = i in breakpoints
        would_exceed_max = current_tokens + next_tokens > MAX_CHUNK_TOKENS
        long_enough = current_tokens >= MIN_CHUNK_TOKENS

        if would_exceed_max or (at_breakpoint and long_enough):
            children.append(" ".join(current))
            current = [next_sentence]
            current_tokens = next_tokens
        else:
            current.append(next_sentence)
            current_tokens += next_tokens

    if current:
        children.append(" ".join(current))

    return children


def semantic_chunk_parent(parent_text: str) -> list[str]:
    """Splits one parent's text into semantically coherent child chunks."""
    sentences = _split_sentences(parent_text)
    if len(sentences) <= 1:
        return sentences

    embed_model = get_embed_model()
    breakpoints = _semantic_breakpoints(sentences, embed_model)
    return _group_into_children(sentences, breakpoints)


def process_json(json_data: dict, source_id: str) -> list[Document]:
    """Processes one uploaded subject/module JSON file end to end.

    - Flattens the JSON into parent units.
    - Writes each parent's full text to the ParentStore.
    - Semantically chunks each parent's text into children.
    - Returns the children as langchain Documents ready to embed, each
      carrying `parent_id` + subject/chapter/section metadata.

    Args:
        json_data: Parsed JSON content (subject/module file).
        source_id: Unique identifier for this upload (e.g. normalized
            filename), used to build stable parent/child ids.

    Returns:
        List of Document objects -- the children to embed and upsert.
    """
    parent_units = load_parent_units(json_data)

    parents_to_save = {}
    child_documents: list[Document] = []

    for p_idx, unit in enumerate(parent_units):
        parent_id = f"{source_id}_p{p_idx}_{uuid.uuid4().hex[:8]}"
        parents_to_save[parent_id] = {
            "text": unit["text"],
            "metadata": unit["metadata"],
        }

        children = chunk_parent(unit["text"], unit["content_type"])
        for c_idx, child_text in enumerate(children):
            child_documents.append(
                Document(
                    page_content=child_text,
                    metadata={
                        **unit["metadata"],
                        "parent_id": parent_id,
                        "child_index": c_idx,
                        "content_type": unit["content_type"],
                    },
                )
            )

    parent_store.save_parents(parents_to_save)
    return child_documents

def chunk_raw_text(raw_text: str) -> list[str]:
    """Treats a flat raw_text chapter (no section/content_type structure)
    as a single 'prose' parent and semantically chunks it."""
    return chunk_parent(raw_text, content_type="prose")