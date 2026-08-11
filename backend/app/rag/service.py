import os
import logging
import asyncio
from typing import Dict, Any, List

import httpx
from dotenv import load_dotenv
from sqlalchemy.orm import Session

from .retriever import (
    retrieve_relevant_context,
    build_context,
)

load_dotenv()

logger = logging.getLogger("rag_service")

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")

OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"

# You can change this model later.
LLM_MODEL = "openai/gpt-4o-mini"

# Number of chunks retrieved from the business knowledge base.
TOP_K = 5

# Ignore chunks with very low similarity.
SIMILARITY_THRESHOLD = 0.30


# =========================================================
# 1. Call OpenRouter
# =========================================================

async def call_llm(
        prompt: str,
        retries: int = 3
) -> str:
    """
    Send the RAG prompt to the OpenRouter LLM.
    """

    if not OPENROUTER_API_KEY:
        raise ValueError(
            "OPENROUTER_API_KEY is not configured."
        )

    headers = {
        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": LLM_MODEL,
        "messages": [
            {
                "role": "system",
                "content": (
                    "You are Udyamix, an AI business assistant. "
                    "Answer using the provided business context. "
                    "Do not invent business information. "
                    "If the context does not contain enough information, "
                    "clearly say that the information is not available."
                ),
            },
            {
                "role": "user",
                "content": prompt,
            },
        ],
        "temperature": 0.1,
    }

    async with httpx.AsyncClient(timeout=60) as client:

        for attempt in range(retries):

            try:

                response = await client.post(
                    OPENROUTER_URL,
                    headers=headers,
                    json=payload,
                )

                response.raise_for_status()

                data = response.json()

                answer = (
                    data["choices"][0]
                    ["message"]
                    ["content"]
                )

                return answer.strip()

            except Exception as e:

                logger.warning(
                    f"LLM attempt {attempt + 1} failed: {e}"
                )

                if attempt == retries - 1:
                    raise

                await asyncio.sleep(1)


# =========================================================
# 2. Build RAG prompt
# =========================================================

def build_rag_prompt(
        question: str,
        context: str
) -> str:
    """
    Build the prompt containing the user's question
    and retrieved business information.
    """

    return f"""
You are answering a question for a specific business.

USER QUESTION:
{question}

RELEVANT BUSINESS INFORMATION:
{context}

INSTRUCTIONS:

1. Answer the user's question directly.
2. Use the business information provided above.
3. Do not invent facts about the business.
4. Do not use unrelated information.
5. If the required information is not present in the
   business information, say that it is not available.
6. Keep the answer clear and useful.
"""


# =========================================================
# 3. Main RAG function
# =========================================================

async def ask_business_assistant(
        db: Session,
        business_id: int,
        question: str,
        top_k: int = TOP_K,
        similarity_threshold: float = SIMILARITY_THRESHOLD,
) -> Dict[str, Any]:
    """
    Main Udyamix RAG pipeline.

    Flow:

        Question
            ↓
        Retriever
            ↓
        Relevant business chunks
            ↓
        Context
            ↓
        LLM
            ↓
        Answer
    """

    if not question or not question.strip():
        raise ValueError(
            "Question cannot be empty."
        )

    question = question.strip()

    logger.info(
        f"RAG question received for business {business_id}"
    )

    # -----------------------------------------------------
    # Retrieve business information
    # -----------------------------------------------------

    chunks = retrieve_relevant_context(
        db=db,
        business_id=business_id,
        query=question,
        top_k=top_k,
        similarity_threshold=similarity_threshold,
    )

    # -----------------------------------------------------
    # Build context
    # -----------------------------------------------------

    context = build_context(chunks)

    # -----------------------------------------------------
    # Build prompt
    # -----------------------------------------------------

    prompt = build_rag_prompt(
        question=question,
        context=context,
    )

    # -----------------------------------------------------
    # Ask LLM
    # -----------------------------------------------------

    answer = await call_llm(prompt)

    # -----------------------------------------------------
    # Return result
    # -----------------------------------------------------

    return {
        "question": question,
        "answer": answer
    }


# =========================================================
# 4. Simple context-only function
# =========================================================

def get_business_context(
        db: Session,
        business_id: int,
        question: str,
        top_k: int = TOP_K,
        similarity_threshold: float = SIMILARITY_THRESHOLD,
) -> List[Dict[str, Any]]:
    """
    Retrieve business information without calling the LLM.

    Useful for debugging and testing RAG retrieval.
    """

    return retrieve_relevant_context(
        db=db,
        business_id=business_id,
        query=question,
        top_k=top_k,
        similarity_threshold=similarity_threshold,
    )