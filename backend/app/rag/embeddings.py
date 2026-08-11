import logging
from typing import List

from sentence_transformers import SentenceTransformer

logger = logging.getLogger("rag_embeddings")


# ---------------------------------------------------------
# Embedding Model
# ---------------------------------------------------------

MODEL_NAME = "all-MiniLM-L6-v2"

_model = None


def get_embedding_model() -> SentenceTransformer:
    """
    Load the embedding model once and reuse it.
    """

    global _model

    if _model is None:
        logger.info(
            f"Loading embedding model: {MODEL_NAME}"
        )

        _model = SentenceTransformer(MODEL_NAME)

        logger.info("Embedding model loaded successfully")

    return _model


# ---------------------------------------------------------
# Generate embedding for ONE text
# ---------------------------------------------------------

def generate_embedding(text: str) -> List[float]:
    """
    Convert one piece of text into an embedding vector.
    """

    if not text or not text.strip():
        raise ValueError(
            "Cannot generate embedding for empty text."
        )

    model = get_embedding_model()

    embedding = model.encode(
        text,
        convert_to_numpy=True,
        normalize_embeddings=True
    )

    return embedding.tolist()


# ---------------------------------------------------------
# Generate embeddings for MULTIPLE chunks
# ---------------------------------------------------------

def generate_embeddings(
        texts: List[str]
) -> List[List[float]]:
    """
    Convert multiple text chunks into embeddings.

    Example:

        [
            "Return policy is 30 days.",
            "Products must be unused.",
            "Refunds take 7 days."
        ]

    becomes:

        [
            [0.12, -0.43, ...],
            [0.21, -0.31, ...],
            [0.09, -0.52, ...]
        ]
    """

    if not texts:
        return []

    cleaned_texts = [
        text.strip()
        for text in texts
        if text and text.strip()
    ]

    if not cleaned_texts:
        return []

    model = get_embedding_model()

    logger.info(
        f"Generating embeddings for {len(cleaned_texts)} chunks"
    )

    embeddings = model.encode(
        cleaned_texts,
        batch_size=32,
        show_progress_bar=False,
        convert_to_numpy=True,
        normalize_embeddings=True
    )

    return embeddings.tolist()