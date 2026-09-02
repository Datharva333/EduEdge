# EduEdge

**EduEdge** is an offline-first AI learning platform for CBSE Class 9–10 students, designed for environments where internet connectivity may be limited or unreliable.

The current MVP combines a **Flutter mobile application**, a **FastAPI backend**, **SQLite**, and a **fully local AI engine** using a quantized GGUF language model.

> **Current offline architecture:** the Android application can operate without internet while communicating with the EduEdge backend and AI engine running locally on a laptop/PC. Fully standalone AI inference directly on Android is planned for a later phase.

---

## Current Features

- User login and registration
- Backend-powered lesson catalogue
- Lesson reading
- AI lesson summarization
- Topic-focused summaries
- Lesson-scoped AI chat
- AI-generated quizzes
- Flashcards
- Mind maps
- Basic progress tracking
- SQLite local persistence
- Local LLM inference without external AI APIs
- Android ↔ local backend communication

### Current Demo Content

| ID | Subject | Lesson |
|---|---|---|
| 1 | Mathematics | Quadratic Equations |
| 2 | Science | Is Matter Around Us Pure? |
| 3 | English | Grammar — Tenses |

Each lesson is mapped by the backend to its corresponding source JSON inside the AI engine.

---

# Architecture

```text
┌─────────────────────┐
│   Flutter Frontend  │
│     Android App     │
└──────────┬──────────┘
           │ HTTP
           ▼
┌─────────────────────┐
│   FastAPI Backend   │
│                     │
│ • Authentication    │
│ • Lessons           │
│ • AI API Bridge     │
│ • Progress          │
│ • SQLite            │
└──────────┬──────────┘
           │ Local HTTP
           ▼
┌─────────────────────┐
│      AI Engine      │
│                     │
│ • Local GGUF LLM    │
│ • llama.cpp         │
│ • Lesson JSON       │
│ • RAG Components    │
└─────────────────────┘
```

For example, summarization follows:

```text
Flutter
   ↓
POST /api/v1/ai/summarize
   ↓
FastAPI receives lessonId
   ↓
lessonId → source_filename
   ↓
AI Engine loads lesson content
   ↓
Local LLM generates summary
   ↓
FastAPI
   ↓
Flutter UI
```

The frontend never needs to know the internal AI-engine file paths.

---

# Technology Stack

### Frontend

- Flutter
- Dart
- Provider
- GoRouter
- Dio
- SharedPreferences

### Backend

- Python
- FastAPI
- SQLAlchemy
- SQLite
- JWT authentication
- Optional PostgreSQL synchronization

### AI Engine

- Python
- `llama-cpp-python`
- GGUF local LLM
- Qwen 2.5 3B Instruct
- Sentence Transformers
- Chroma/RAG components
- JSON-based lesson content

---

# Project Structure

```text
EduEdge/
│
├── frontend/
│   ├── lib/
│   │   ├── core/
│   │   ├── features/
│   │   └── services/
│   └── android/
│
├── backend/
│   └── app/
│       ├── ai_bridge/
│       ├── config/
│       ├── database/
│       ├── models/
│       ├── repositories/
│       ├── routers/
│       ├── schemas/
│       ├── services/
│       └── scripts/
│
├── ai-engine/
│   ├── app/
│   ├── data/raw/
│   ├── models/
│   └── api.py
│
└── README.md
```

---

# Running EduEdge Locally

## 1. Start the AI Engine

```powershell
cd ai-engine

.\.venv\Scripts\python.exe -m uvicorn api:app --host 127.0.0.1 --port 8001
```

AI health check:

```text
http://127.0.0.1:8001/health
```

Expected response:

```json
{
  "status": "ok"
}
```

---

## 2. Start the Backend

For local development, PostgreSQL synchronization can be disabled:

```powershell
cd backend

$env:SYNC_ENABLED="false"
$env:AI_ENGINE_BASE_URL="http://127.0.0.1:8001"

.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Backend health:

```text
http://127.0.0.1:8000/health
```

Swagger API documentation:

```text
http://127.0.0.1:8000/docs
```

### Seed Demo Lessons

```powershell
python -m app.scripts.seed_demo_data
```

---

## 3. Run the Flutter Application

```powershell
cd frontend

flutter pub get
flutter analyze
```

Expected:

```text
No issues found!
```

For a physical Android phone connected through USB:

```powershell
adb reverse tcp:8000 tcp:8000
```

Then:

```powershell
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

For LAN communication, replace `127.0.0.1` with the backend machine's local IP.

Example:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

---

# Demo Account

```text
Email:    student@eduedge.com
Password: test1234
```

This account is intended for local development and testing.

---

# Important API Endpoints

### Backend

```http
GET /health
```

```http
GET /api/v1/lessons
GET /api/v1/lessons/{lessonId}
```

### AI Status

```http
GET /api/v1/ai/health
```

### Summarization

```http
POST /api/v1/ai/summarize
```

Example:

```json
{
  "lessonId": "1"
}
```

Focused summary:

```json
{
  "lessonId": "2",
  "topic": "Tyndall effect"
}
```

### AI Chat

```http
POST /api/v1/ai/chat
```

```json
{
  "lessonId": "1",
  "message": "What is the discriminant?"
}
```

### Quiz Generation

```http
POST /api/v1/ai/quiz
```

```json
{
  "lessonId": "2",
  "num_questions": 5
}
```

---

# Demo Flow

```text
Login
  ↓
Home
  ↓
Select Lesson
  ↓
Read Lesson
  ↓
AI Hub
  ├── Summarize
  ├── Ask AI
  ├── Quiz
  ├── Flashcards
  └── Mind Map
  ↓
Progress
```

Useful test questions:

```text
Mathematics:
What is the discriminant?

Science:
Explain the Tyndall effect.

English:
When do we use the simple present tense?
```

---

# Development Checks

Before pushing significant changes:

### Flutter

```powershell
cd frontend
dart format lib
flutter analyze
```

### Backend

```powershell
cd backend
.\.venv\Scripts\python.exe -m compileall app
```

### AI Engine

```powershell
cd ai-engine
.\.venv\Scripts\python.exe -m py_compile api.py
```

---

# Git Hygiene

Do not commit:

```text
.venv/
build/
.dart_tool/
.gradle/
__pycache__/
*.pyc
*.db
.env
*.gguf
models/
demo-rag-chroma/
.eduedge_patch_backup/
```

Educational JSON content under:

```text
ai-engine/data/raw/
```

may be committed when it forms part of the EduEdge lesson library.

---

# Current Limitations

EduEdge is currently an MVP.

- AI generation is CPU-bound and can be slow depending on hardware.
- Fully standalone Android AI inference is not yet implemented.
- Mobile offline operation currently depends on a local EduEdge laptop/PC.
- The complete lesson-scoped vector RAG pipeline is still under development.
- Progress tracking is currently basic.
- Flashcards and mind maps currently use lightweight lesson-specific content.
- PostgreSQL synchronization is optional and not required for the local MVP.
- The lesson catalogue is intentionally small while the main workflow is stabilized.

---

# Current Development Status

Active development branch:

```text
feature/real-summarize
```

Current focus:

```text
Real Summarization
        ↓
Lesson-Scoped AI Chat
        ↓
AI Quiz Generation
        ↓
Maths / Science / English Integration
        ↓
Cross-Machine Testing
        ↓
Stable Offline MVP
```

The immediate goal is a reliable student workflow:

```text
Select Lesson
→ Read
→ Summarize
→ Ask Questions
→ Take Quiz
→ Review
→ Track Progress
```

The project currently prioritizes **stability, correctness, offline usability, and complete end-to-end functionality** over adding unnecessary features.

---

## License

License information will be added once finalized.