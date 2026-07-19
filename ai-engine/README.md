# AI-ENGINE

Offline Retrieval-Augmented Generation (RAG) engine for the EduEdge project.

This module is responsible for:
- Loading educational documents
- Processing and chunking text
- Creating vector embeddings
- Building a FAISS vector database
- Retrieving relevant context
- Generating answers using a local Large Language Model (LLM)

---

# Architecture

```
User Query
     │
     ▼
Retriever (FAISS)
     │
     ▼
Relevant Chunks
     │
     ▼
Prompt Template
     │
     ▼
Local LLM
     │
     ▼
Generated Answer
```

---

# Folder Structure

```
AI-ENGINE/
│
├── app/
│   ├── chunk.py        # Document chunking
│   ├── config.py       # Configuration settings
│   ├── embed.py        # Embedding generation
│   ├── llm.py          # Local LLM initialization
│   ├── prompts.py      # Prompt templates
│   ├── rag.py          # Main RAG pipeline
│   ├── retrieve.py     # Vector retrieval
│   └── utils.py        # Helper functions
│
├── data/
│   ├── raw/            # Original PDF files
│   └── processed/      # Processed chunks
│
├── models/
│   ├── llm/            # GGUF language models
│   └── embeddings/     # Local embedding models
│
├── vectorstore/
│   └── faiss_index/    # FAISS vector database
│
├── scripts/
│   ├── ingest.py       # Load PDFs and create chunks
│   ├── build_index.py  # Generate embeddings and build FAISS index
│   └── test_rag.py     # End-to-end testing
│
├── requirements.txt
└── README.md
```

---

# Technology Stack

| Component | Technology |
|-----------|------------|
| Framework | LangChain |
| PDF Loader | PyMuPDFLoader |
| Text Splitter | RecursiveCharacterTextSplitter |
| Embedding Model | BAAI/bge-small-en-v1.5 |
| Embedding Framework | HuggingFace Embeddings |
| Vector Store | FAISS |
| Local LLM | llama-cpp-python |
| LLM Format | GGUF |

---

# Workflow

### 1. Document Ingestion
- Load PDF documents
- Extract text
- Split into chunks
- Store processed chunks

### 2. Vector Index Creation
- Generate embeddings for every chunk
- Store embeddings in a FAISS index

### 3. Retrieval
- Convert the user query into an embedding
- Search FAISS for the most relevant chunks

### 4. Generation
- Combine retrieved context with the user query
- Send the prompt to the local LLM
- Return the generated answer

---

# Components

### `scripts/ingest.py`
Loads PDF documents and prepares them for chunking.

### `app/chunk.py`
Splits documents into overlapping chunks.

### `scripts/build_index.py`
Generates embeddings and creates the FAISS vector database.

### `app/embed.py`
Loads and manages the embedding model.

### `app/retrieve.py`
Retrieves the most relevant document chunks.

### `app/prompts.py`
Stores prompt templates used for RAG.

### `app/llm.py`
Loads and configures the local GGUF model.

### `app/rag.py`
Coordinates the complete Retrieval-Augmented Generation pipeline.

---

# Future Enhancements

- DOCX document support
- TXT document support
- OCR for scanned PDFs
- Image extraction from PDFs
- Hybrid search (Vector + BM25)
- Response citations
- Streaming responses
- Model switching support
- Moving from FAISS to Qdrant for scalability