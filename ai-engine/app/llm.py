"""Local, in-process chat generation using llama-cpp-python.

Only the chat/generation model is GGUF. Embeddings and re-ranking use
sentence-transformers folders instead (see app/embed.py and app/rag.py).
"""

from typing import Optional

from llama_cpp import Llama

from app.config import CHAT_MODEL_PATH, MAX_TOKENS, N_CTX, N_GPU_LAYERS, N_THREADS
from app.prompts import system_prompt
from threading import Lock

_chat_llm: Optional[Llama] = None
_llm_lock = Lock()

def get_chat_llm() -> Llama:
    """Lazily loads and caches the chat model. Loaded once per process."""
    global _chat_llm
    if _chat_llm is None:
        _chat_llm = Llama(
            model_path=CHAT_MODEL_PATH,
            n_ctx=N_CTX,
            n_threads=N_THREADS,
            n_gpu_layers=N_GPU_LAYERS,
            verbose=False,
        )
    return _chat_llm


def call_llm(
    context: str,
    prompt: str,
    system: str | None = None,
    max_tokens: int = MAX_TOKENS,
):
    llm = get_chat_llm()

    with _llm_lock:
        stream = llm.create_chat_completion(
            messages=[
                {
                    "role": "system",
                    "content": system or system_prompt,
                },
                {
                    "role": "user",
                    "content": f"Context: {context}, Question: {prompt}",
                },
            ],
            stream=True,
            max_tokens=max_tokens,
        )

        for chunk in stream:
            delta = chunk["choices"][0]["delta"]

            if "content" in delta:
                yield delta["content"]