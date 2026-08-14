"""Querying the vector collection."""

from app.config import N_RESULTS
from app.embed import get_vector_collection


def query_collection(prompt: str, n_results: int = N_RESULTS):
    """Queries the vector collection with a given prompt to retrieve relevant documents.

    Args:
        prompt: The search query text to find relevant documents.
        n_results: Maximum number of results to return.

    Returns:
        dict: Query results containing documents, distances and metadata from
            the collection.

    Raises:
        ChromaDBError: If there are issues querying the collection.
    """
    collection = get_vector_collection()
    results = collection.query(query_texts=[prompt], n_results=n_results)
    return results
