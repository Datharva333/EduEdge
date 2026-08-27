"""Local, in-process chat generation using llama-cpp-python.

Only the chat/generation model is GGUF. Embeddings and re-ranking use
sentence-transformers folders instead (see app/embed.py and app/rag.py).
"""

from typing import Optional

from llama_cpp import Llama

from app.config import CHAT_MODEL_PATH, MAX_TOKENS, N_CTX, N_GPU_LAYERS, N_THREADS
from app.prompts import system_prompt

_chat_llm: Optional[Llama] = None


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


def call_llm(context: str, prompt: str, system: str | None = None):
    """Streams a response from the local chat model given context and a question.

    Uses `create_chat_completion(..., stream=True)` with proper system/user
    roles and yields text chunks, so `st.write_stream()` in app.py keeps
    working exactly as before.

    Args:
        context: String containing the relevant context for answering the question.
        prompt: String containing the user's question.
        system: Optional system prompt override. Defaults to the QA
            `system_prompt` from app.prompts -- pass `quiz_system_prompt`
            (or any other) to reuse this same call/stream plumbing for a
            different task, e.g. quiz generation.

    Yields:
        String chunks of the generated response as they become available.

    Raises:
        RuntimeError: If there are issues running the local model.
    """
    llm = get_chat_llm()
    stream = llm.create_chat_completion(
        messages=[
            {"role": "system", "content": system or system_prompt},
            {"role": "user", "content": f"Context: {context}, Question: {prompt}"},
        ],
        stream=True,
        max_tokens=MAX_TOKENS,
    )
    for chunk in stream:
        delta = chunk["choices"][0]["delta"]
        if "content" in delta:
            yield delta["content"]