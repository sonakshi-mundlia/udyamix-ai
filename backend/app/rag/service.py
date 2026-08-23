import os
import logging
import asyncio
from typing import Dict, Any, List, Optional

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

# =========================================================
# Configuration
# =========================================================

LLM_MODEL = "openai/gpt-4o-mini"

TOP_K = 5

SIMILARITY_THRESHOLD = 0.30


# =========================================================
# 1. Call OpenRouter LLM
# =========================================================

async def call_llm(
        prompt: str,
        retries: int = 3
) -> str:
    """
    Send the RAG prompt to the OpenRouter LLM.

    The LLM is instructed to produce evidence-based
    business answers and avoid unsupported claims.
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
                "content": """
You are Udyamix, an evidence-based business intelligence assistant.

Your job is to produce accurate, useful and evidence-based
business answers.

STRICT RULES:

1. Use ONLY the business data, verified metrics and retrieved
   business evidence provided in the prompt.

2. NEVER invent:
   - numbers
   - transactions
   - customers
   - products
   - dates
   - business events
   - financial information

3. VERIFIED BUSINESS METRICS are authoritative.

4. Never present an assumption or hypothesis as a fact.

5. Clearly distinguish between:

   FACTS
   Information directly supported by the provided data.

   EVIDENCE
   Business information that supports the conclusion.

   INFERENCE
   A possible explanation derived from the evidence.

   RECOMMENDATION
   A practical action the business could consider.

6. Do NOT claim that one event caused another unless the
   provided evidence supports that conclusion.

7. If there is insufficient evidence, explicitly say:

   "Insufficient evidence."

8. Never create missing information to make an answer
   look complete.

9. Preserve provided numerical values accurately.

10. If multiple explanations are possible, mention the
    important alternatives instead of selecting one without
    evidence.

11. Recommendations must be based on the available evidence.

12. Do not give false certainty.

13. Confidence must reflect the strength and completeness
    of the available evidence.

14. Do not use general business knowledge as if it were
    specific knowledge about this business.

15. If the retrieved documents are unrelated to the user's
    question, do not use them to construct an answer.

The goal is:

ACCURACY > COMPLETENESS > CONFIDENCE

Do not produce confident-sounding information that is unsupported.
"""
            },
            {
                "role": "user",
                "content": prompt,
            },
        ],

        # Low temperature gives more consistent answers.
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

                if not answer:
                    raise ValueError(
                        "LLM returned an empty response."
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
# 2. Get verified business metrics
# =========================================================

def get_business_metrics(
        db: Session,
        business_id: int,
        question: str
) -> Dict[str, Any]:
    """
    Retrieve verified numerical business metrics.

    IMPORTANT:
    This function is intentionally empty until the actual
    Udyamix database schema is connected.

    Do NOT let the LLM calculate or invent these values.

    Later this function can return values such as:

        {
            "revenue": 1000000,
            "previous_revenue": 1050000,
            "revenue_change_percent": -4.76,
            "expenses": 700000,
            "previous_expenses": 620000,
            "expense_change_percent": 12.90,
            "profit": 300000,
            "previous_profit": 430000,
            "profit_change_percent": -30.23
        }

    These values should come directly from PostgreSQL
    calculations.
    """

    # -----------------------------------------------------
    # TODO:
    #
    # Connect this function to your actual Udyamix
    # PostgreSQL tables.
    # -----------------------------------------------------

    metrics: Dict[str, Any] = {}

    return metrics


# =========================================================
# 3. Verify LLM insight
# =========================================================

def verify_insight(
        answer: str,
        metrics: Dict[str, Any]
) -> str:
    """
    Perform basic verification of the generated insight.

    Current behavior:

    - Ensures an answer exists.
    - If verified metrics are unavailable, clearly informs
      that numerical claims could not be independently
      verified.

    This is intentionally conservative.

    A stronger deterministic claim verifier can be added
    once the actual business metrics schema is available.
    """

    if not answer or not answer.strip():
        raise ValueError(
            "LLM returned an empty answer."
        )

    answer = answer.strip()

    # -----------------------------------------------------
    # No verified metrics available
    # -----------------------------------------------------

    if not metrics:

        logger.warning(
            "No verified metrics available for insight "
            "verification."
        )

        return (
                answer
                + "\n\n"
                  "VERIFICATION STATUS:\n"
                  "- No verified business metrics were available "
                  "for this question.\n"
                  "- Numerical claims could not be independently "
                  "verified against business records."
        )

    # -----------------------------------------------------
    # Metrics are available.
    #
    # A stronger claim-level verification system should
    # be implemented here later.
    # -----------------------------------------------------

    logger.info(
        f"Insight generated with {len(metrics)} "
        f"verified business metrics."
    )

    return answer


# =========================================================
# 4. Build RAG prompt
# =========================================================

def build_rag_prompt(
        question: str,
        context: str,
        metrics: Optional[Dict[str, Any]] = None,
) -> str:
    """
    Build the complete evidence-based prompt.

    The LLM receives:

        1. User question
        2. Verified business metrics
        3. Retrieved RAG evidence
    """

    if metrics:

        metrics_text = "\n".join(
            f"- {key}: {value}"
            for key, value in metrics.items()
        )

    else:

        metrics_text = (
            "No verified business metrics were available "
            "for this question."
        )

    return f"""
USER QUESTION
=============

{question}


VERIFIED BUSINESS METRICS
=========================

{metrics_text}


RETRIEVED BUSINESS EVIDENCE
============================

{context}


TASK
====

Answer the user's question using ONLY the verified metrics
and retrieved business evidence above.


REASONING RULES
===============

1. Identify facts directly supported by the data.

2. Identify evidence supporting the answer.

3. Separate facts from possible explanations.

4. Do not claim causation unless the evidence supports it.

5. If the available information is insufficient, explicitly
   state:

   "Insufficient evidence."

6. Never invent missing numbers or business information.

7. If there are multiple plausible explanations, mention them.

8. Recommendations must be connected to the available evidence.

9. Preserve numerical values exactly as provided.

10. Do not treat general business knowledge as a fact about
    this specific business.

11. Do not use irrelevant retrieved documents.


RESPONSE FORMAT
===============

FACTS:
- List only facts directly supported by the provided data.

EVIDENCE:
- List the important evidence supporting the answer.

INSIGHT:
- Explain what the evidence means for the business.
- Clearly identify any inference or possible explanation.

RECOMMENDATION:
- Give practical actions based on the available evidence.
- If no recommendation can be justified, say so.

CONFIDENCE:
- High / Medium / Low

LIMITATIONS:
- Explain what information is missing or uncertain.
"""


# =========================================================
# 5. Main RAG function
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

        User question
             ↓
        Query embedding
             ↓
        PGVector retrieval
             ↓
        Retrieved business evidence
             +
        Verified business metrics
             ↓
        Evidence-based prompt
             ↓
        LLM
             ↓
        Verification
             ↓
        Final answer
    """

    # -----------------------------------------------------
    # Validate question
    # -----------------------------------------------------

    if not question or not question.strip():

        raise ValueError(
            "Question cannot be empty."
        )

    question = question.strip()

    logger.info(
        f"RAG question received for business {business_id}"
    )

    # -----------------------------------------------------
    # 1. Retrieve business evidence
    # -----------------------------------------------------

    chunks = retrieve_relevant_context(
        db=db,
        business_id=business_id,
        query=question,
        top_k=top_k,
        similarity_threshold=similarity_threshold,
    )

    logger.info(
        f"Retrieved {len(chunks)} relevant chunks "
        f"for business {business_id}"
    )

    # -----------------------------------------------------
    # 2. Build RAG context
    # -----------------------------------------------------

    context = build_context(chunks)

    # -----------------------------------------------------
    # 3. Get verified business metrics
    # -----------------------------------------------------

    metrics = get_business_metrics(
        db=db,
        business_id=business_id,
        question=question,
    )

    logger.info(
        f"Retrieved {len(metrics)} verified metrics "
        f"for business {business_id}"
    )

    # -----------------------------------------------------
    # 4. Build evidence-based prompt
    # -----------------------------------------------------

    prompt = build_rag_prompt(
        question=question,
        context=context,
        metrics=metrics,
    )

    # -----------------------------------------------------
    # 5. Ask LLM
    # -----------------------------------------------------

    answer = await call_llm(prompt)

    # -----------------------------------------------------
    # 6. Verify LLM answer
    # -----------------------------------------------------

    verified_answer = verify_insight(
        answer=answer,
        metrics=metrics,
    )

    # -----------------------------------------------------
    # 7. Return final result
    # -----------------------------------------------------

    return {
        "question": question,
        "answer": verified_answer,
        "retrieved_chunks": len(chunks),
        "has_verified_metrics": bool(metrics),
    }


# =========================================================
# 6. Context-only function
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

