# EduEdge

EduEdge is an **offline-first AI-powered educational application for CBSE Class 9 and 10 students**, designed especially for environments where internet access may be limited, unreliable, or unavailable.

The project is being developed with one central objective:

> A student should be able to open EduEdge on an Android phone, access educational content, use AI learning assistance, take quizzes, and retain progress without requiring an internet connection, cloud AI service, laptop, or external backend server.

The project originally used a Flutter frontend with a FastAPI/backend-based AI architecture. It has now been significantly reworked toward a **standalone Android architecture with on-device AI inference**.

---

## Current Project Status

The hardest part of the standalone MVP — **running an actual LLM directly on Android** — is already working.

### Functional

- Local lesson access
- On-device GGUF model loading
- Offline AI lesson summarization
- Offline lesson-scoped Ask AI
- Multilingual AI responses
- Quiz UI and scoring system
- Local AI quiz generation pipeline
- Quiz parser and local fallback questions
- Android model import through file picker
- Model context reset between independent generations
- Student-facing AI functionality without laptop-side inference

### Still To Be Completed

- Local progress persistence
- Fully offline/local login or onboarding
- Improved AI quiz generation reliability
- Stronger validation of AI-generated quiz answer keys
- Removal/audit of any remaining runtime internet dependencies
- Final airplane-mode end-to-end testing
- UI/UX cleanup and polish
- Additional lesson content
- Optional future tools such as flashcards and mind maps

---

# Architecture

The target standalone student runtime is:

```text
Flutter Android Application
        |
        +---- Local Lesson Content
        |
        +---- Local Progress Storage
        |
        +---- LocalAiService
                    |
                    +---- llama_flutter_android
                                |
                                +---- Qwen3.5 GGUF
```

The repository still contains backend and AI-engine components from the earlier architecture.

These components may remain useful for development, future connected features, administration, or experimentation, but:

> The core student experience must not depend on the backend being available.

---

# Technology Stack

## Mobile Application

- Flutter
- Dart
- Provider
- GoRouter
- Android

## On-Device AI

- `llama_flutter_android`
- GGUF model format
- Qwen3.5
- CPU inference
- Local prompt grounding using lesson content

## Existing Backend / Reference Architecture

- Python
- FastAPI
- SQLite
- Existing AI-engine components

The backend should not be reintroduced as a requirement for core offline student features.

---

# On-Device Language Model

The current model selected for the standalone MVP is:

```text
Qwen3.5-0.8B-Q4_K_M.gguf
```

Approximate size:

```text
508 MB
```

Current inference configuration:

```text
Threads: 4
Context size: 1024
GPU layers: 0
```

Android minimum SDK:

```text
API 26
```

Android package:

```text
com.eduedge.eduedge
```

GPU/Vulkan acceleration is currently not required.

The model choice has already been benchmarked against other Qwen variants and should be considered **frozen for the MVP** unless a serious blocker is discovered.

---

# Model Installation

The GGUF model is intentionally **not stored in Git**.

EduEdge includes a model import workflow using the Android file picker.

The selected model is copied into the application's private storage, typically under a path similar to:

```text
/data/user/0/com.eduedge.eduedge/files/models/Qwen3.5-0.8B-Q4_K_M.gguf
```

The actual application path is resolved through `path_provider`.

Typical development flow:

```text
Copy GGUF to phone
        ↓
Open EduEdge model import
        ↓
Select GGUF
        ↓
EduEdge copies it to private storage
        ↓
LocalAiService loads the model
```

Do not depend on `adb run-as`, `/Android/data/...`, or other developer-only filesystem tricks for the final product workflow.

---

# Local AI Service

The main AI integration is located in:

```text
frontend/lib/services/local_ai_service.dart
```

The service currently handles:

- locating the local model
- importing GGUF files
- checking model availability
- loading the model
- local inference
- context clearing
- output cleanup
- lesson summarization
- lesson-grounded Q&A
- quiz generation
- quiz parsing
- model shutdown and disposal

A particularly important implementation detail is that the model context is cleared before independent requests.

This prevents previous conversations or generations from contaminating later requests.

Do not remove this behavior without a verified replacement.

---

# Offline Lesson System

Student-facing lesson content is now available locally.

The standalone lesson flow does not require a backend lesson endpoint for the primary demo path.

Current demo content includes subjects such as:

```text
Mathematics
- Quadratic Equations

Science
- Is Matter Around Us Pure?

English
- Tenses

Additional local demo lessons are also included.
```

The current objective is not to build a massive content library.

The priority is to prove that the entire learning flow works reliably offline.

---

# Offline Summarization

Lesson summarization is performed directly on the Android device.

Flow:

```text
Lesson content
      ↓
LocalAiService
      ↓
Qwen3.5
      ↓
Short lesson summary
```

The summarization prompt is intentionally compact because the current model context is limited to 1024 tokens.

Lesson text is trimmed before generation where necessary.

The summary feature currently requests short, simple output suitable for Class 9 and 10 students.

This feature is considered functional for the MVP.

---

# Offline Ask AI

Ask AI has been migrated from the earlier backend AI endpoint to the on-device model.

Current flow:

```text
Selected lesson
      +
Student question
      ↓
LocalAiService
      ↓
Qwen3.5
      ↓
Local answer
```

The model is grounded using the current lesson text.

A useful capability discovered during testing is **multilingual interaction**.

Questions have been successfully tested in languages including English, Hindi and Marathi, and the model is capable of responding in several additional languages.

This behavior should be preserved.

Do not introduce an English-only restriction unless required by a future product decision.

Because the current model is only 0.8B parameters, prompts should remain concise and output sizes should remain controlled.

---

# Quiz System

The quiz interface is functional.

It supports:

- multiple-choice questions
- four options
- answer selection
- correct/incorrect indication
- next-question navigation
- final score
- retry/new quiz
- offline fallback questions

The current AI quiz pipeline is:

```text
Lesson
   ↓
LocalAiService.generateQuiz()
   ↓
Qwen3.5
   ↓
Structured text response
   ↓
Dart parser
   ↓
Quiz questions
```

The parser validates the basic output format.

---

## Current Quiz Limitation

The 0.8B model is not consistently reliable when asked to generate several complete MCQs in a single generation.

Observed problems have included:

- generating only one question instead of three
- incomplete structured output
- copying prompt placeholders
- academically weak generated questions
- potentially incorrect answer keys

The application therefore retains curated offline fallback questions.

A generated question must never be trusted merely because its text format parses correctly.

For an educational application:

> Correctness is more important than dynamically generating every question.

---

## Recommended Future Quiz Architecture

A more reliable approach is to generate questions individually:

```text
Generate Question 1
        ↓
Parse + Validate
        ↓
Generate Question 2
        ↓
Parse + Validate
        ↓
Generate Question 3
        ↓
Parse + Validate
        ↓
Combine Results
```

If a generated question fails validation, replace only that question with a curated local fallback.

For the MVP, using entirely curated offline questions is also acceptable if required for reliability.

---

# Progress Persistence

Local progress persistence is one of the highest-priority unfinished tasks.

The final standalone app should save information such as:

```text
lesson completed
quiz score
best quiz score
last opened lesson
basic student progress
```

The data must survive application restarts.

For the MVP, a simple implementation using `SharedPreferences` is acceptable.

A heavier database or cloud synchronization system is not required yet.

---

# Authentication / Offline Entry

The final application must not require a backend authentication server simply to access learning features.

The team should implement a local/offline-friendly entry system.

Possible MVP approaches include:

```text
Local student profile
Offline onboarding
Skip login
Local username/profile
```

The requirement is:

```text
Fresh install
→ no internet
→ no backend
→ student can still enter EduEdge
```

Complex cloud authentication is outside the current MVP scope.

---

# Runtime Internet Dependency Audit

The Flutter application should be tested carefully for hidden runtime network dependencies.

One previously observed issue involved `google_fonts` attempting to fetch fonts at runtime when offline.

The team should verify whether this dependency still exists.

If necessary:

- use system fonts
- use bundled offline-safe assets
- remove runtime font fetching

Core screens must not depend on remote fonts, remote images, analytics services, backend APIs, or other network resources.

---

# Running The Project

From the repository root:

```powershell
cd frontend
flutter pub get
flutter analyze
flutter devices
flutter run -d YOUR_DEVICE_ID
```

If dependencies are already cached and the development PC is offline:

```powershell
flutter pub get --offline
```

---

# Standalone MVP Definition Of Done

The final test should be performed with:

```text
Phone Wi-Fi OFF
Phone mobile data OFF
Laptop backend OFF
Laptop AI engine OFF
No external inference server
```

The following workflow should succeed:

```text
Launch EduEdge
      ↓
Enter application locally
      ↓
Open local lesson
      ↓
Read lesson
      ↓
Generate local summary
      ↓
Ask local AI a question
      ↓
Open quiz
      ↓
Answer 3 questions
      ↓
View score
      ↓
Save progress
      ↓
Close application
      ↓
Reopen application
      ↓
Progress still exists
```

When this flow works reliably, the standalone MVP can be considered complete.

---

# Development Priorities

## P0 — Complete Before MVP Handoff

1. Local progress persistence
2. Offline/local authentication or app entry
3. Safe and reliable quiz behavior
4. Runtime internet dependency cleanup
5. Full airplane-mode regression test

## P1 — Product Quality

1. Better loading states
2. Better error handling
3. Navigation cleanup
4. UI consistency
5. Typography/spacing cleanup
6. Offline model-missing experience

## P2 — Future Development

- flashcards
- mind maps
- recommendations
- advanced RAG
- larger lesson library
- cloud synchronization
- analytics
- teacher/admin tools
- GPU acceleration
- larger-model experimentation

P2 work should not delay completion of P0.

---

# Important Development Rules

Do not replace the working on-device AI architecture with a cloud API.

Do not make core learning features dependent on the backend again.

Do not commit GGUF models.

Do not remove context clearing between independent AI generations.

Preserve multilingual Ask AI.

Keep prompts compact because the model context is currently 1024 tokens.

Validate structured AI output before using it.

Never blindly trust generated academic answer keys.

Prefer curated local fallback content over incorrect generated content.

Avoid unnecessary project-wide rewrites.

Make small, testable changes.

Test important student functionality on a physical Android device.

---

# Git Workflow

The standalone work has been merged into:

```text
main
```

`main` should now be treated as the canonical integrated branch.

For new work:

```bash
git checkout main
git pull origin main
git checkout -b feature/<task-name>
```

After implementation and testing:

```bash
git add <relevant-files>
git commit -m "Describe the completed feature"
git push origin feature/<task-name>
```

Merge the feature into `main` after verification.

Avoid maintaining multiple long-lived branches containing already-merged work.

---

# Do Not Commit

Do not commit:

```text
*.gguf
build/
.dart_tool/
.gradle/
.venv/
venv/
__pycache__/
.env
temporary backups
generated build reports
local development databases
```

Always inspect:

```bash
git status
```

before committing.

---

# Project Direction

Every future EduEdge feature should be evaluated against this principle:

> Can this help a student learn effectively when their Android phone is the only computing device available and internet access cannot be assumed?

The immediate objective is not to maximize the number of features.

The objective is to make the existing offline learning experience reliable, coherent, and genuinely usable.