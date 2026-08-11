import os
import logging
from pathlib import Path
from typing import List

from pypdf import PdfReader
from sqlalchemy import text
from sqlalchemy.orm import Session

from .embeddings import generate_embeddings

logger = logging.getLogger("rag_ingestion")

# How many characters should be in each chunk
CHUNK_SIZE = 1000

# Overlap prevents important information from being split badly
CHUNK_OVERLAP = 200


# ---------------------------------------------------------
# 1. Extract text from PDF
# ---------------------------------------------------------

def extract_text_from_pdf(file_path: str) -> str:
    """
    Extract all readable text from a PDF.
    """

    reader = PdfReader(file_path)

    pages = []

    for page_number, page in enumerate(reader.pages):
        try:
            text_content = page.extract_text()

            if text_content:
                pages.append(text_content)

        except Exception as e:
            logger.warning(
                f"Could not extract page {page_number}: {e}"
            )

    return "\n".join(pages).strip()


# ---------------------------------------------------------
# 2. Split text into chunks
# ---------------------------------------------------------

def split_text(
        text_content: str,
        chunk_size: int = CHUNK_SIZE,
        overlap: int = CHUNK_OVERLAP
) -> List[str]:
    """
    Split large text into overlapping chunks.
    """

    if not text_content:
        return []

    text_content = text_content.strip()

    chunks = []

    start = 0
    text_length = len(text_content)

    while start < text_length:

        end = start + chunk_size

        chunk = text_content[start:end].strip()

        if chunk:
            chunks.append(chunk)

        # Move forward while keeping overlap
        start = end - overlap

    return chunks


# ---------------------------------------------------------
# 3. Save document information
# ---------------------------------------------------------

def save_document(
        db: Session,
        business_id: int,
        filename: str,
        file_path: str
) -> int:
    """
    Store the uploaded document in the database.

    Returns:
        document_id
    """

    result = db.execute(
        text("""
            INSERT INTO business_documents
                (business_id, filename, file_path)
            VALUES
                (:business_id, :filename, :file_path)
            RETURNING id
        """),
        {
            "business_id": business_id,
            "filename": filename,
            "file_path": file_path,
        }
    )

    document_id = result.scalar_one()

    db.commit()

    return document_id


# ---------------------------------------------------------
# 4. Save chunks + embeddings
# ---------------------------------------------------------

def save_chunks(
        db: Session,
        business_id: int,
        document_id: int,
        chunks: List[str],
        embeddings: List[List[float]]
):
    """
    Store document chunks and their embeddings.
    """

    if len(chunks) != len(embeddings):
        raise ValueError(
            "Number of chunks and embeddings must be equal"
        )

    for index, (chunk, embedding) in enumerate(
            zip(chunks, embeddings)
    ):

        db.execute(
            text("""
                INSERT INTO document_chunks
                    (
                        business_id,
                        document_id,
                        chunk_index,
                        chunk_text,
                        embedding
                    )
                VALUES
                    (
                        :business_id,
                        :document_id,
                        :chunk_index,
                        :chunk_text,
                        :embedding
                    )
            """),
            {
                "business_id": business_id,
                "document_id": document_id,
                "chunk_index": index,
                "chunk_text": chunk,
                "embedding": embedding,
            }
        )

    db.commit()


# ---------------------------------------------------------
# 5. Main ingestion function
# ---------------------------------------------------------

def ingest_document(
        db: Session,
        business_id: int,
        file_path: str,
        filename: str
) -> int:
    """
    Complete ingestion pipeline:

    PDF
      ↓
    Extract text
      ↓
    Split into chunks
      ↓
    Generate embeddings
      ↓
    Store in PostgreSQL + pgvector

    Returns:
        document_id
    """

    logger.info(
        f"Starting ingestion for business {business_id}: {filename}"
    )

    # ---------------------------------------------
    # Extract text
    # ---------------------------------------------

    file_extension = Path(file_path).suffix.lower()

    if file_extension != ".pdf":
        raise ValueError(
            f"Unsupported file type: {file_extension}. "
            "Currently only PDF is supported."
        )

    document_text = extract_text_from_pdf(file_path)

    if not document_text:
        raise ValueError(
            "No readable text was found in the document."
        )

    logger.info(
        f"Extracted {len(document_text)} characters"
    )

    # ---------------------------------------------
    # Split into chunks
    # ---------------------------------------------

    chunks = split_text(document_text)

    if not chunks:
        raise ValueError(
            "Document could not be split into chunks."
        )

    logger.info(
        f"Created {len(chunks)} chunks"
    )

    # ---------------------------------------------
    # Save document
    # ---------------------------------------------

    document_id = save_document(
        db=db,
        business_id=business_id,
        filename=filename,
        file_path=file_path
    )

    # ---------------------------------------------
    # Generate embeddings
    # ---------------------------------------------

    embeddings = generate_embeddings(chunks)

    logger.info(
        f"Generated {len(embeddings)} embeddings"
    )

    # ---------------------------------------------
    # Save chunks + embeddings
    # ---------------------------------------------

    save_chunks(
        db=db,
        business_id=business_id,
        document_id=document_id,
        chunks=chunks,
        embeddings=embeddings
    )

    logger.info(
        f"Successfully ingested document {document_id}"
    )

    return document_id