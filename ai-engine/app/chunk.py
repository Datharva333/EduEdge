#text chunking"""PDF loading and text chunking (unchanged from the original demo)."""

import os
import tempfile

from langchain_community.document_loaders import PyMuPDFLoader
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from streamlit.runtime.uploaded_file_manager import UploadedFile

from app.config import CHUNK_OVERLAP, CHUNK_SEPARATORS, CHUNK_SIZE


def process_document(uploaded_file: UploadedFile) -> list[Document]:
    """Processes an uploaded PDF file by converting it to text chunks.

    Takes an uploaded PDF file, saves it temporarily, loads and splits the
    content into text chunks using recursive character splitting.

    Args:
        uploaded_file: A Streamlit UploadedFile object containing the PDF file.

    Returns:
        A list of Document objects containing the chunked text from the PDF.

    Raises:
        IOError: If there are issues reading/writing the temporary file.
    """
    with tempfile.NamedTemporaryFile(
        mode="wb",
        suffix=".pdf",
        delete=False,
    ) as temp_file:
        temp_file.write(uploaded_file.read())
        temp_path = temp_file.name

    loader = PyMuPDFLoader(temp_path)
    docs = loader.load()

    os.remove(temp_path)

    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=CHUNK_SIZE,
        chunk_overlap=CHUNK_OVERLAP,
        separators=CHUNK_SEPARATORS,
    )

    return text_splitter.split_documents(docs)
