import logging
from typing import List, Dict, Any

from sqlalchemy import text
from sqlalchemy.orm import Session

from .embeddings import generate_embedding

logger = logging.getLogger("rag_retriever")


# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------

DEFAULT_TOP_K = 5


# ---------------------------------------------------------
# Retrieve relevant business chunks
# ---------------------------------------------------------

def retrieve_business_context(
        db: Session,
        business_id: int,
        query: str,
        top_k: int = DEFAULT_TOP_K
) -> List[Dict[str, Any]]:
    """
    Retrieve the most relevant document chunks for a
    particular business.

    Flow:

        User question
             ↓
        Generate query embedding
             ↓
        PostgreSQL + pgvector
             ↓
        Similarity search
             ↓
        Top K relevant chunks
    """

    if not query or not query.strip():
        return []

    if top_k <= 0:
        return []

    # -----------------------------------------------------
    # 1. Generate embedding for the user's question
    # -----------------------------------------------------

    query_embedding = generate_embedding(query)

    # pgvector accepts the vector as a string representation
    vector_string = "[" + ",".join(
        str(float(value))
        for value in query_embedding
    ) + "]"

    # -----------------------------------------------------
    # 2. Search PostgreSQL using cosine distance
    # -----------------------------------------------------

    sql = text("""
        SELECT
            dc.id,
            dc.document_id,
            dc.chunk_index,
            dc.chunk_text,

            1 - (dc.embedding <=> CAST(:query_embedding AS vector))
                AS similarity

        FROM document_chunks dc

        WHERE dc.business_id = :business_id
          AND dc.embedding IS NOT NULL

        ORDER BY dc.embedding
                 <=> CAST(:query_embedding AS vector)

        LIMIT :top_k
    """)

    result = db.execute(
        sql,
        {
            "business_id": business_id,
            "query_embedding": vector_string,
            "top_k": top_k,
        }
    )

    rows = result.fetchall()

    # -----------------------------------------------------
    # 3. Convert database results into Python objects
    # -----------------------------------------------------

    chunks = []

    for row in rows:

        chunks.append({
            "id": row.id,
            "document_id": row.document_id,
            "chunk_index": row.chunk_index,
            "text": row.chunk_text,
            "similarity": float(row.similarity or 0),
        })

    logger.info(
        f"Retrieved {len(chunks)} chunks "
        f"for business {business_id}"
    )

    return chunks


# ---------------------------------------------------------
# Retrieve only sufficiently relevant chunks
# ---------------------------------------------------------

def retrieve_relevant_context(
        db: Session,
        business_id: int,
        query: str,
        top_k: int = DEFAULT_TOP_K,
        similarity_threshold: float = 0.30
) -> List[Dict[str, Any]]:
    """
    Retrieve relevant chunks and remove results that
    have very low similarity.
    """

    chunks = retrieve_business_context(
        db=db,
        business_id=business_id,
        query=query,
        top_k=top_k
    )

    relevant_chunks = [
        chunk
        for chunk in chunks
        if chunk["similarity"] >= similarity_threshold
    ]

    return relevant_chunks


# ---------------------------------------------------------
# Convert retrieved chunks into LLM context
# ---------------------------------------------------------

def build_context(
        chunks: List[Dict[str, Any]]
) -> str:
    """
    Convert retrieved chunks into a single text context
    that can be passed to the LLM.
    """

    if not chunks:
        return "No relevant business information was found."

    context_parts = []

    for index, chunk in enumerate(chunks, start=1):

        context_parts.append(
            f"""
--- Business Document Context {index} ---

{chunk["text"]}
"""
        )

    return "\n".join(context_parts)

