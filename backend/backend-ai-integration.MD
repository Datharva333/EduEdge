# EduEdge Backend ↔ AI Engine — Integration Guide

**Who this is for:** you, building the AI engine (chunking, embeddings, RAG, translation).
**What this is:** exactly what your FastAPI service needs to expose so the backend can talk to it — the request/response shape for each endpoint, when the backend calls it, and what it does with the result.

---

## 1. The big picture

Two completely separate codebases, two separate FastAPI servers:

```
eduedge-backend/     ← auth, database, sync, business logic (not built by you)
eduedge-ai-engine/   ← chunking, embeddings, vector DB, LLM, RAG (you)
```

They only ever talk over plain HTTP. The backend never imports your code, never touches your vector DB, never runs your model. It just sends a JSON request to a URL and reads back a JSON response. That URL is configured once, in the backend's settings, as `AI_ENGINE_BASE_URL` (e.g. `http://localhost:8001` while we're both developing locally).

The backend calls you at two very different times:
- **Offline/admin time** — when someone runs the ingestion script to add new NCERT content, or the translation batch script. Not triggered by a student using the app.
- **(Possibly) live time** — if we decide the app needs a server-proxied "ask a question" path for when a device is online. **Not built yet — see the open question at the bottom.**

---

## 2. Endpoints your service needs to expose

### `POST /chunk`

**Called from:** the ingestion script, once per chapter, whenever someone adds/updates a chapter of content.

**Request body sent to you:**
```json
{
  "raw_text": "full extracted text of one chapter...",
  "chapter_id": "uuid-of-the-chapter-in-our-db",
  "strategy_version": 1
}
```
`strategy_version` is how we tell you which chunker to use if you ever have more than one (e.g. `1` = your current parent-child recursive chunker, `2` = a future semantic chunker). If you only have one chunker right now, you can ignore this field — just make sure whatever version number you're actually running matches what we've hardcoded on our side (currently `1`) so we stay in sync. **Tell us if/when this changes.**

**Response we expect back from you:**
```json
{
  "chunks": [
    {
      "text": "the chunk's actual text",
      "text_hash": "sha256 hash of the text",
      "token_start": 0,
      "token_end": 128,
      "parent_chunk_index": null,
      "semantic_break_score": null
    }
  ],
  "embedding_model_version": "e.g. all-MiniLM-L6-v2"
}
```
- `text` — **required, this is the important one.** We store this ourselves (we don't re-derive it from your vector DB), so it must be the real chunk text, not a summary or placeholder.
- `text_hash` — a hash of `text`. If it's easier for you, we can compute this ourselves on our side instead of you sending it — tell me if you'd rather do that.
- `token_start` / `token_end` — token offsets within the chapter.
- `parent_chunk_index` — **this is an index into the `chunks` array in this same response** (e.g. `2` means "my parent is `chunks[2]`"), not a database ID — we don't have database IDs yet at the moment you're responding. Set to `null` if this chunk has no parent (or your strategy is flat, non-hierarchical).
- `semantic_break_score` — only fill this in once your chunker is semantic-aware. `null` is fine for now.
- `embedding_model_version` — a string identifying which embedding model you used (e.g. `"all-MiniLM-L6-v2"` or whatever it actually is). We only use this for bookkeeping (to know when embeddings need regenerating) — we never see or store the actual vectors.

⚠️ **This is currently our best guess at your actual response shape — not confirmed against your running code.** Please send back a real example response from your `/chunk` endpoint so we can double-check field names match exactly.

---

### `POST /embed`

**Called from:** the ingestion script, if/when we need embeddings generated as a separate step from chunking (if your `/chunk` endpoint already generates embeddings internally as part of chunking, this endpoint might not even be needed separately — tell me which way you've built it).

**Request:**
```json
{ "texts": ["chunk text 1", "chunk text 2"] }
```

**Response we expect:**
```json
{ "model_version": "all-MiniLM-L6-v2", "count": 2 }
```
Important: **we don't want or store the actual vectors** — those stay entirely in your Chroma DB. We only care about `model_version` (for bookkeeping) and `count` (as a sanity check that nothing got dropped). Please don't send the embedding arrays themselves — keeps the payload small and keeps us honestly out of your retrieval internals.

---

### `POST /cache/lookup`

**Called from:** not actively used yet — wired up on our side but nothing calls it currently. Reserved for later if we add a "check if this question was already answered" step before hitting the full RAG pipeline.

**Request:**
```json
{ "query_hash": "sha256 of the question" }
```

**Response — per your own spec, always this for now:**
```json
{ "hit": false, "answer": null }
```
No action needed from you until we actually start using this — the stub response above is exactly what you already said you'd return.

---

### `POST /translate` — ⚠️ not in your original spec, please confirm

We added this endpoint on our side to call IndicTrans2, based on your note that translation should run "during sync windows only." **We don't know if you're planning to own this or if it should be a separate concern entirely** — please confirm.

**Request we'd send:**
```json
{ "text": "chunk text in English", "target_language": "hi" }
```

**Response we'd expect:**
```json
{ "translated_text": "translated chunk text" }
```

If IndicTrans2 isn't something you're planning to expose via your FastAPI service, tell us and we'll figure out a different plan (maybe a small standalone script instead of a live endpoint).

---

## 3. What we do with your responses (so you know why the shapes matter)

- `/chunk` output → we insert one row per chunk into our own database, including the full `text` — this is what gets sent down to student devices later, so if `text` is wrong/truncated/missing, that's what breaks, not something in your RAG pipeline.
- `/embed` output → used only for the `embedding_model_version` bookkeeping described above.
- We never call your RAG/question-answering logic directly from a live user request right now — see the open question below.

---

## 4. Open question — needs your input before we go further

**Does the Flutter app ever need to ask a question through the server (live), or is 100% of question-answering done on-device using content already synced down?**

This matters because:
- If it's **100% on-device**, your `/chunk`, `/embed`, `/translate` endpoints are the entire integration — nothing else needed from you.
- If there's **any server-proxied live Q&A path**, we need one more endpoint from you (something like `POST /answer` → `{"answer": ..., "sources": [...], "confidence": ...}`) and a new route on our side to call it. Not built yet — waiting on your answer here before adding it.

---

## 5. How to test this together locally

1. Run your AI engine on some port, e.g. `http://localhost:8001`.
2. In the backend's `.env`, set `AI_ENGINE_BASE_URL=http://localhost:8001`.
3. On the backend side, we'll run `python -m app.scripts.ingest_ncert_content` (once the PDF text extraction is wired up) — it'll call your `/chunk` endpoint for real and we can see immediately if the shapes match.
4. Fastest sanity check before that: you can `curl` your own `/chunk` endpoint with the exact request JSON shown above and paste us the raw response — we'll compare it against `ai_bridge/schemas.py` and flag any mismatch before running anything live.