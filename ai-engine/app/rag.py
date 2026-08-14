# """Cross-encoder re-ranking of retrieved chunks."""

# from typing import Optional

# from sentence_transformers import CrossEncoder

# from app.config import CROSS_ENCODER_MODEL_PATH, RERANK_TOP_K

# _encoder: Optional[CrossEncoder] = None


# def _get_encoder() -> CrossEncoder:
#     """Lazily loads and caches the cross-encoder model (loaded once per process)."""
#     global _encoder
#     if _encoder is None:
#         _encoder = CrossEncoder(CROSS_ENCODER_MODEL_PATH)
#     return _encoder


# def re_rank_cross_encoders(
#     prompt: str, documents: list[str]
# ) -> tuple[str, list[int]]:
#     """Re-ranks documents using a cross-encoder model for more accurate relevance scoring.

#     Uses the MS MARCO MiniLM cross-encoder model to re-rank the input documents
#     based on their relevance to the query prompt. Returns the concatenated text
#     of the top-ranked documents along with their indices.

#     NOTE: the original version of this function referenced `prompt` as a
#     global variable instead of taking it as a parameter, which only worked by
#     accident because a global named `prompt` happened to exist in the
#     Streamlit script. It's now passed in explicitly.

#     Args:
#         prompt: The user's question, used to score each document's relevance.
#         documents: List of document strings to be re-ranked.

#     Returns:
#         tuple: A tuple containing:
#             - relevant_text (str): Concatenated text from the top ranked documents.
#             - relevant_text_ids (list[int]): Indices of the top ranked documents.

#     Raises:
#         ValueError: If documents list is empty.
#         RuntimeError: If the cross-encoder model fails to load or rank documents.
#     """
#     relevant_text = ""
#     relevant_text_ids = []

#     encoder_model = _get_encoder()
#     ranks = encoder_model.rank(prompt, documents, top_k=RERANK_TOP_K)

#     for rank in ranks:
#         relevant_text += documents[rank["corpus_id"]]
#         relevant_text_ids.append(rank["corpus_id"])

#     return relevant_text, relevant_text_ids
"""Cross-encoder re-ranking of retrieved children, followed by resolving
the reranked children back to their parent blocks for LLM context."""

from typing import Optional

from sentence_transformers import CrossEncoder

from app.config import CROSS_ENCODER_MODEL_PATH, RERANK_TOP_K
from app import parent_store

_encoder: Optional[CrossEncoder] = None


def _get_encoder() -> CrossEncoder:
    """Lazily loads and caches the cross-encoder model (loaded once per process)."""
    global _encoder
    if _encoder is None:
        _encoder = CrossEncoder(CROSS_ENCODER_MODEL_PATH)
    return _encoder


def re_rank_cross_encoders(prompt: str, documents: list[str]) -> list[int]:
    """Re-ranks candidate child chunks using a cross-encoder.

    Scores each (prompt, document) pair jointly -- more accurate than the
    bi-encoder similarity Chroma used to fetch the candidate set, since it
    actually reads both texts together instead of comparing precomputed
    vectors.

    Args:
        prompt: The user's question.
        documents: Candidate child chunk texts, as returned by Chroma.

    Returns:
        Indices into `documents` for the top RERANK_TOP_K matches, ordered
        best to worst.

    Raises:
        ValueError: If documents is empty.
    """
    if not documents:
        raise ValueError("No documents to re-rank.")

    encoder_model = _get_encoder()
    ranks = encoder_model.rank(prompt, documents, top_k=RERANK_TOP_K)
    return [rank["corpus_id"] for rank in ranks]


def resolve_parent_context(
    reranked_ids: list[int], metadatas: list[dict]
) -> tuple[str, list[str]]:
    """Maps reranked children to their parent blocks and dedupes.

    A child chunk is small and precise -- good for matching a narrow
    question. But the LLM answers better with the surrounding section, not
    an isolated fragment. This looks up each reranked child's parent_id in
    the ParentStore, drops duplicates (multiple top children often share
    one parent), and returns the combined parent text.

    Args:
        reranked_ids: Indices from re_rank_cross_encoders.
        metadatas: Chroma metadata dicts for the same candidate set that
            was reranked -- each child's metadata includes its `parent_id`.

    Returns:
        tuple:
            - context (str): Deduped parent texts, joined with blank lines.
              This is what gets passed to call_llm.
            - parent_ids (list[str]): The unique parent_ids used, in order
              of their best-ranked child's appearance.
    """
    parent_ids = [metadatas[i]["parent_id"] for i in reranked_ids]
    parents = parent_store.get_parents(parent_ids)  # dedupes, preserves order

    context = "\n\n".join(p["text"] for p in parents)
    unique_parent_ids = list(dict.fromkeys(parent_ids))
    return context, unique_parent_ids