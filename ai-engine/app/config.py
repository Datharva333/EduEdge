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
CHAT_MODEL_PATH = "models/llm/Qwen2.5-3B-instruct-Q3_K_M.gguf"
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

# --- Semantic chunking (children) ---
MIN_CHUNK_TOKENS = 60          # merge forward if a candidate child is smaller than this
MAX_CHUNK_TOKENS = 250         # force-split if a coherent run exceeds this
BREAKPOINT_PERCENTILE = 80     # distance percentile above which a sentence gap = topic shift
WINDOW_SIZE = 1                # sentences of context on each side when embedding for breakpoint detection

# --- Parent store (full section/subsection text, looked up post-rerank) ---
PARENT_STORE_PATH = "./parent_store.db"

# --- content-type-aware chunking ---
# worked_example / formula blocks are never semantically split; this is
# only a last-resort fallback (blank-line paragraph split, no breakpoint
# detection) for the rare block that's unusually long.
NON_SEMANTIC_HARD_CAP_TOKENS = 500

# --- Raw content JSON files (uploaded chapter source files) ---
DATA_RAW_DIR = "data/raw"