# """Vector store setup and ingestion (local sentence-transformers embeddings + ChromaDB)."""

# from typing import List, Optional
# from chromadb import EmbeddingFunction
# import chromadb
# import streamlit as st
# from langchain_core.documents import Document
# from sentence_transformers import SentenceTransformer

# from app.config import CHROMA_PATH, COLLECTION_NAME, EMBED_MODEL_PATH

# _embed_model: Optional[SentenceTransformer] = None


# def _get_embed_model() -> SentenceTransformer:
#     """Lazily loads and caches the embedding model. Loaded once per process."""
#     global _embed_model
#     if _embed_model is None:
#         _embed_model = SentenceTransformer(EMBED_MODEL_PATH)
#     return _embed_model


# class SentenceTransformerEmbeddingFunction(EmbeddingFunction):
#     """ChromaDB-compatible embedding function backed by sentence-transformers.

#     Newer chromadb versions (1.x) require embedding functions to formally
#     subclass `chromadb.EmbeddingFunction` and implement `name()` --
#     otherwise `get_or_create_collection` raises
#     `AttributeError: ... object has no attribute 'name'`. `get_config()` /
#     `build_from_config()` are also implemented so Chroma can serialize this
#     embedding function's identity alongside the collection.
#     """

#     def __init__(self):
#         # Deliberately not calling super().__init__() -- the base class's
#         # default __init__ only emits a deprecation warning.
#         pass

#     def __call__(self, input: List[str]) -> List[List[float]]:
#         model = _get_embed_model()
#         embeddings = model.encode(input, convert_to_numpy=True)
#         return embeddings.tolist()

#     @staticmethod
#     def name() -> str:
#         return "sentence-transformers-local"

#     def get_config(self) -> dict:
#         return {"model_path": EMBED_MODEL_PATH}

#     @staticmethod
#     def build_from_config(config: dict) -> "SentenceTransformerEmbeddingFunction":
#         return SentenceTransformerEmbeddingFunction()

"""Vector store setup and ingestion (local sentence-transformers embeddings + ChromaDB)."""

from typing import List, Optional

import chromadb
import streamlit as st
from chromadb import EmbeddingFunction
from langchain_core.documents import Document
from sentence_transformers import SentenceTransformer

from app.config import CHROMA_PATH, COLLECTION_NAME, EMBED_MODEL_PATH

_embed_model: Optional[SentenceTransformer] = None


def get_embed_model() -> SentenceTransformer:
    """Lazily loads and caches the embedding model. Loaded once per process."""
    global _embed_model
    if _embed_model is None:
        _embed_model = SentenceTransformer(EMBED_MODEL_PATH)
    return _embed_model


class SentenceTransformerEmbeddingFunction(EmbeddingFunction):
    """ChromaDB-compatible embedding function backed by sentence-transformers.

    Newer chromadb versions (1.x) require embedding functions to formally
    subclass `chromadb.EmbeddingFunction` and implement `name()` --
    otherwise `get_or_create_collection` raises
    `AttributeError: ... object has no attribute 'name'`. `get_config()` /
    `build_from_config()` are also implemented so Chroma can serialize this
    embedding function's identity alongside the collection.
    """

    def __init__(self):
        # Deliberately not calling super().__init__() -- the base class's
        # default __init__ only emits a deprecation warning.
        pass

    def __call__(self, input: List[str]) -> List[List[float]]:
        model = get_embed_model()
        embeddings = model.encode(input, convert_to_numpy=True)
        return embeddings.tolist()

    @staticmethod
    def name() -> str:
        return "sentence-transformers-local"

    def get_config(self) -> dict:
        return {"model_path": EMBED_MODEL_PATH}

    @staticmethod
    def build_from_config(config: dict) -> "SentenceTransformerEmbeddingFunction":
        return SentenceTransformerEmbeddingFunction()


def get_vector_collection() -> chromadb.Collection:
    """Gets or creates a ChromaDB collection for vector storage.

    Uses a local sentence-transformers embedding model (in-process, no
    server) and initializes a persistent ChromaDB client. Returns a
    collection that can be used to store and query document embeddings.

    Returns:
        chromadb.Collection: A ChromaDB collection configured with the
            sentence-transformers embedding function and cosine similarity space.
    """
    embedding_function = SentenceTransformerEmbeddingFunction()

    chroma_client = chromadb.PersistentClient(path=CHROMA_PATH)
    return chroma_client.get_or_create_collection(
        name=COLLECTION_NAME,
        embedding_function=embedding_function,
        metadata={"hnsw:space": "cosine"},
    )


def add_to_vector_collection(all_splits: list[Document], file_name: str):
    """Adds document splits to a vector collection for semantic search.

    Takes a list of document splits and adds them to a ChromaDB vector
    collection along with their metadata and unique IDs based on the filename.

    Args:
        all_splits: List of Document objects containing text chunks and metadata.
        file_name: String identifier used to generate unique IDs for the chunks.

    Returns:
        None. Displays a success message via Streamlit when complete.

    Raises:
        ChromaDBError: If there are issues upserting documents to the collection.
    """
    collection = get_vector_collection()
    documents, metadatas, ids = [], [], []

    for idx, split in enumerate(all_splits):
        documents.append(split.page_content)
        metadatas.append(split.metadata)
        ids.append(f"{file_name}_{idx}")

    collection.upsert(
        documents=documents,
        metadatas=metadatas,
        ids=ids,
    )
    st.success("Data added to the vector store!")