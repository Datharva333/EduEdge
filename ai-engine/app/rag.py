#main rag pipeline"""Cross-encoder re-ranking of retrieved chunks."""

from typing import Optional

from sentence_transformers import CrossEncoder

from app.config import CROSS_ENCODER_MODEL_PATH, RERANK_TOP_K

_encoder: Optional[CrossEncoder] = None


def _get_encoder() -> CrossEncoder:
    """Lazily loads and caches the cross-encoder model (loaded once per process)."""
    global _encoder
    if _encoder is None:
        _encoder = CrossEncoder(CROSS_ENCODER_MODEL_PATH)
    return _encoder


def re_rank_cross_encoders(
    prompt: str, documents: list[str]
) -> tuple[str, list[int]]:
    """Re-ranks documents using a cross-encoder model for more accurate relevance scoring.

    Uses the MS MARCO MiniLM cross-encoder model to re-rank the input documents
    based on their relevance to the query prompt. Returns the concatenated text
    of the top-ranked documents along with their indices.

    NOTE: the original version of this function referenced `prompt` as a
    global variable instead of taking it as a parameter, which only worked by
    accident because a global named `prompt` happened to exist in the
    Streamlit script. It's now passed in explicitly.

    Args:
        prompt: The user's question, used to score each document's relevance.
        documents: List of document strings to be re-ranked.

    Returns:
        tuple: A tuple containing:
            - relevant_text (str): Concatenated text from the top ranked documents.
            - relevant_text_ids (list[int]): Indices of the top ranked documents.

    Raises:
        ValueError: If documents list is empty.
        RuntimeError: If the cross-encoder model fails to load or rank documents.
    """
    relevant_text = ""
    relevant_text_ids = []

    encoder_model = _get_encoder()
    ranks = encoder_model.rank(prompt, documents, top_k=RERANK_TOP_K)

    for rank in ranks:
        relevant_text += documents[rank["corpus_id"]]
        relevant_text_ids.append(rank["corpus_id"])

    return relevant_text, relevant_text_ids
