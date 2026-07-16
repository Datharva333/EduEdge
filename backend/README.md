# 🛠️ EduEdge Backend Architecture

## Overview

EduEdge follows an **Offline-First Architecture**, ensuring students can continue learning even without an internet connection.

The backend is responsible for authentication, content delivery, synchronization, cloud storage, and communication with AI services. After the initial setup, all learning activities are performed using locally stored data.

---

## Backend Tech Stack

- **FastAPI** – REST API & Backend Services
- **PostgreSQL** – Cloud Database
- **SQLite** – Local Offline Database
- **JWT Authentication** – Secure Login
- **JSON Content Repository** – NCERT Chapters & Educational Content

---

# Backend Folder Structure

```text
backend/
│
├── app/
│   ├── api/                    # REST API Routes
│   │   ├── auth.py
│   │   ├── content.py
│   │   ├── sync.py
│   │   ├── progress.py
│   │   ├── quiz.py
│   │   └── ai.py
│   │
│   ├── core/                   # Configuration & Security
│   │   ├── config.py
│   │   ├── security.py
│   │   ├── logger.py
│   │   └── exceptions.py
│   │
│   ├── database/
│   │   ├── postgres.py
│   │   ├── sqlite.py
│   │   ├── models.py
│   │   └── migrations/
│   │
│   ├── schemas/                # Pydantic Models
│   │
│   ├── services/
│   │   ├── auth_service.py
│   │   ├── content_service.py
│   │   ├── sync_service.py
│   │   ├── quiz_service.py
│   │   └── ai_service.py
│   │
│   ├── cms/                    # Content Management System
│   │   ├── upload.py
│   │   ├── content_manager.py
│   │   └── version_manager.py
│   │
│   ├── sync/
│   │   ├── delta_sync.py
│   │   ├── queue_manager.py
│   │   ├── retry.py
│   │   └── conflict_resolution.py
│   │
│   ├── content/
│   │   ├── class6/
│   │   ├── class7/
│   │   ├── class8/
│   │   ├── class9/
│   │   ├── class10/
│   │   ├── class11/
│   │   └── class12/
│   │
│   ├── utils/
│   │
│   └── main.py
│
├── requirements.txt
├── .env
└── README.md
```

---

## Backend Components

### 1. FastAPI Server

Responsible for:

- User Authentication
- Content Download APIs
- Sync APIs
- AI Integration APIs
- Version Management
- Error Handling & Logging

---

### 2. PostgreSQL

Stores cloud data such as:

- Users
- Student Progress
- Quiz Attempts
- Homework
- Sync Logs
- Content Metadata

---

### 3. Content Management System (CMS)

An admin portal to manage educational content.

Features:

- Upload NCERT Chapters
- Manage Classes & Subjects
- Upload Quizzes
- Manage Homework
- Publish Content Updates
- Version Control

---

### 4. SQLite (Offline Database)

Stores downloaded content on the student's device.

- Lessons
- Chapters
- Quiz Attempts
- Homework
- Progress
- Settings
- Sync Queue

---

# Backend Workflow

```text
Student Installs App
        │
        ▼
Login / Register
        │
        ▼
Select Class & Subjects
        │
        ▼
FastAPI Downloads Required Content
        │
        ▼
Store in SQLite
        │
        ▼
Offline Learning
        │
        ▼
Progress Saved Locally
        │
        ▼
Internet Available
        │
        ▼
Sync with FastAPI
        │
        ▼
Cloud Database Updated
```

---

## Offline Workflow

```text
User Action
      │
      ▼
SQLite Database
      │
      ▼
Save Changes
      │
      ▼
Mark as Unsynced
      │
      ▼
Continue Learning
```

---

## Online Workflow

```text
Internet Available
      │
      ▼
Sync Manager
      │
      ▼
FastAPI
      │
      ▼
PostgreSQL
      │
      ▼
Mark Records as Synced
```

---

## Content Download Flow

1. Student installs EduEdge.
2. Student logs in and selects their **Class** and **Subjects**.
3. FastAPI retrieves the required NCERT content from the Content Repository.
4. Selected content is downloaded and stored in the local SQLite database.
5. Students can access lessons, quizzes, and progress completely offline.
6. When internet is available, only updated content is downloaded using **Delta Sync**.

---

## Project Responsibilities

### Backend

- FastAPI
- PostgreSQL
- SQLite Schema
- Authentication
- Content Management System
- Synchronization
- REST APIs
- Logging & Error Handling

### Frontend

- Flutter UI
- API Integration
- Repository Layer
- SQLite Integration

### AI Module

- Lesson Summarization
- Quiz Generation
- Homework Generation
- Mind Maps
- Personalized Learning

---

## Design Principle

> **Offline First → Local Storage → Sync Later**

Every user action is first stored locally in SQLite and synchronized with the cloud automatically whenever an internet connection becomes available.