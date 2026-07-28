"""Central configuration for the RAG app.

Model layout on disk (all local, no network calls, no server):

    models/
        llm/my-model.gguf                        -- chat model (llama.cpp GGUF)
        embeddings/myembedding-model/             -- embedding model (sentence-transformers folder)
        cross-encoder-model/                      -- reranker model (sentence-transformers/HF folder)

Only the chat/generation model is GGUF, loaded via llama-cpp-python.
The embedding model and the cross-encoder reranker are standard
sentence-transformers folders, loaded via the `sentence-transformers`
library.
"""

# --- Chroma vector store ---
CHROMA_PATH = "./demo-rag-chroma"
COLLECTION_NAME = "RAG_PROJECT"

# --- Local model paths ---
CHAT_MODEL_PATH = "models/llm/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
EMBED_MODEL_PATH = "models/embeddings/multilingual-e5-small"
CROSS_ENCODER_MODEL_PATH = "models/cross-encoder-model/ms-marco-MiniLM-L6-v2"

# --- Retrieval / re-ranking ---
N_RESULTS = 10
RERANK_TOP_K = 3

# --- Chunking ---
CHUNK_SIZE = 400
CHUNK_OVERLAP = 100
CHUNK_SEPARATORS = ["\n\n", "\n", " ", ".", "?", "!"]

# --- llama-cpp-python runtime settings (chat model only) ---
N_CTX = 4096
N_THREADS = 8
N_GPU_LAYERS = 0  # set to 0 to force CPU-only
MAX_TOKENS = 1024
