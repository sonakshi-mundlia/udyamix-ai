import os
import json
import logging
import httpx
import asyncio

from datetime import datetime, timedelta
from typing import List

from sqlalchemy.orm import Session
from sqlalchemy import text
from dotenv import load_dotenv

from ..models.business_model import Business
from ..schemas.ai_insight_schema import (
    AIInsightResponse,
    AIInsightExtraData,
)
from ..rag.service import get_business_context


# ==========================================================
# CONFIGURATION
# ==========================================================

load_dotenv()

logger = logging.getLogger("ai_insight_service")

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")

OPENROUTER_URL = (
    "https://openrouter.ai/api/v1/chat/completions"
)

AI_MODEL = "openai/gpt-4o-mini"

_HTTP_CLIENT = httpx.AsyncClient(
    timeout=90
)


# ==========================================================
# LANGUAGE MAP
# ==========================================================

LANGUAGE_MAP = {
    "en": "English",
    "hi": "Hindi",
    "ta": "Tamil",
    "te": "Telugu",
    "mr": "Marathi",
    "bn": "Bengali",
    "gu": "Gujarati",
    "kn": "Kannada",
    "ml": "Malayalam",
    "pa": "Punjabi",
    "or": "Odia",
    "as": "Assamese",
    "ur": "Urdu",
    "ks": "Kashmiri",
    "kok": "Konkani",
    "sd": "Sindhi",
    "mni": "Manipuri",
    "ne": "Nepali",
    "sa": "Sanskrit",
    "brx": "Bodo",
    "sat": "Santhali",
    "mai": "Maithili",
    "doi": "Dogri",
}


# ==========================================================
# CACHE
# ==========================================================

_AI_INSIGHTS_CACHE = {}


# ==========================================================
# OPENROUTER / LLM CALL
# ==========================================================

async def _openai_chat(
        prompt: str,
        retries: int = 3,
) -> str:

    """
    Calls OpenRouter.

    IMPORTANT ARCHITECTURE:

        Backend
           |
           | calculates numbers
           v
        Authoritative metrics
           |
           v
          LLM
           |
           | interprets only
           v
        Qualitative insight

    The LLM must NEVER become the source of truth
    for numerical business calculations.
    """

    if not OPENROUTER_API_KEY:
        raise ValueError(
            "OPENROUTER_API_KEY is not configured."
        )

    headers = {
        "Authorization": (
            f"Bearer {OPENROUTER_API_KEY}"
        ),
        "Content-Type": "application/json",
    }

    system_prompt = """
You are Udyamix AI, an evidence-based business
intelligence analyst.

Your job is to interpret VERIFIED business data
provided by the backend.

==================================================
IMPORTANT ARCHITECTURE RULE
==================================================

The backend is the ONLY source of truth for
numerical business calculations.

The backend calculates:

- total sales
- total expenses
- profit
- loss
- customer count
- changes
- percentage changes
- trends

You MUST NOT calculate or modify these values.

==================================================
DO NOT INVENT BUSINESS FACTS
==================================================

Never invent:

- revenue
- expenses
- profit
- loss
- customers
- transactions
- products
- suppliers
- dates
- financial losses
- business events
- business policies
- root causes

Only use information supplied in the prompt.

==================================================
NUMERICAL DATA
==================================================

The backend-provided metric values are authoritative.

==================================================
NUMERICAL DATA RULE
==================================================

The backend-provided numerical values are the ONLY
source of truth.

You MAY explicitly mention backend-provided numerical
values in your title, summary, explanation, or other
qualitative text.

However, every numerical value you mention MUST be
copied exactly from the authoritative backend metrics.

You MUST NOT:

- calculate new numbers
- modify backend numbers
- round backend numbers differently
- calculate new percentages
- calculate profit
- calculate loss
- calculate revenue
- calculate customer counts
- calculate financial impact
- create comparison values
- derive new financial values
- estimate financial losses

For example, if the backend provides:

current_value = 2000
previous_value = 0
change_value = 2000
change_percentage = null
trend = "increasing"

You MAY say:

"Total sales are 2000 for the current period."

You MAY say:

"The backend records a change of 2000 from the
previous period."

You MAY say:

"The previous period value was 0 and the current
period value is 2000."

You MUST NOT say:

"Sales increased by 100%."

because the backend did not provide that percentage.

You MUST NOT calculate the percentage yourself.

You MUST NOT say:

"Sales generated 2000 more revenue than expected."

because "expected revenue" was not provided.

You MUST NOT invent any numerical business fact.

==================================================
ROOT CAUSE
==================================================

A confirmed root cause can ONLY be stated when
the supplied business evidence directly supports it.

If there is insufficient evidence, say:

"Insufficient evidence to determine the root cause."

Possible explanations must remain hypotheses.

Do not present assumptions as facts.

==================================================
EVIDENCE
==================================================

Evidence must come ONLY from the supplied
business context.

Never invent evidence.

==================================================
RECOMMENDATIONS
==================================================

Recommendations should be connected to the
observed metric and available evidence.

Avoid unsupported assumptions.

==================================================
CONFIDENCE
==================================================

Use:

High confidence:
Strong direct evidence.

Medium confidence:
Some evidence exists but uncertainty remains.

Low confidence:
Limited evidence or mostly inference.

Return confidence as a number from 0 to 1.

==================================================
FINANCIAL IMPACT
==================================================

Do NOT calculate financial impact.

The backend has not independently calculated
financial impact.

Therefore you must NOT provide:

- financial_value
- estimated_revenue_loss

The backend will handle these fields.

==================================================
OUTPUT
==================================================

Return ONLY valid JSON.

Return one insight for each metric supplied
by the backend.

Do not return metrics or calculations.

Only return qualitative insight information.
"""

    payload = {
        "model": AI_MODEL,

        "messages": [
            {
                "role": "system",
                "content": system_prompt,
            },
            {
                "role": "user",
                "content": prompt,
            },
        ],

        "temperature": 0.1,

        "max_tokens": 4000,

        "response_format": {
            "type": "json_schema",

            "json_schema": {
                "name": "udyamix_ai_insight",
                "strict": True,

                "schema": {
                    "type": "object",

                    "properties": {
                        "insights": {
                            "type": "array",

                            "items": {
                                "type": "object",

                                "properties": {

                                    "metric_name": {
                                        "type": "string"
                                    },

                                    "title": {
                                        "type": "string"
                                    },

                                    "summary": {
                                        "type": "string"
                                    },

                                    "root_cause": {
                                        "type": "object",

                                        "properties": {
                                            "primary": {
                                                "type": "string"
                                            },

                                            "possible_causes": {
                                                "type": "array",
                                                "items": {
                                                    "type": "string"
                                                }
                                            },

                                            "evidence": {
                                                "type": "array",
                                                "items": {
                                                    "type": "string"
                                                }
                                            },

                                            "confidence": {
                                                "type": "number",
                                                "minimum": 0,
                                                "maximum": 1
                                            },
                                        },

                                        "required": [
                                            "primary",
                                            "possible_causes",
                                            "evidence",
                                            "confidence",
                                        ],

                                        "additionalProperties": False,
                                    },

                                    "recommendation": {
                                        "type": "object",

                                        "properties": {
                                            "priority": {
                                                "type": "string"
                                            },

                                            "immediate_actions": {
                                                "type": "array",
                                                "items": {
                                                    "type": "string"
                                                }
                                            },

                                            "short_term_actions": {
                                                "type": "array",
                                                "items": {
                                                    "type": "string"
                                                }
                                            },

                                            "long_term_actions": {
                                                "type": "array",
                                                "items": {
                                                    "type": "string"
                                                }
                                            },
                                        },

                                        "required": [
                                            "priority",
                                            "immediate_actions",
                                            "short_term_actions",
                                            "long_term_actions",
                                        ],

                                        "additionalProperties": False,
                                    },

                                    "action_plan": {
                                        "type": "array",

                                        "items": {
                                            "type": "object",

                                            "properties": {
                                                "step": {
                                                    "type": "integer"
                                                },

                                                "action": {
                                                    "type": "string"
                                                },

                                                "priority": {
                                                    "type": "string"
                                                },
                                            },

                                            "required": [
                                                "step",
                                                "action",
                                                "priority",
                                            ],

                                            "additionalProperties": False,
                                        },
                                    },

                                    "expected_outcome": {
                                        "type": "string"
                                    },

                                    "monitor": {
                                        "type": "array",

                                        "items": {
                                            "type": "string"
                                        },
                                    },
                                },

                                "required": [
                                    "metric_name",
                                    "title",
                                    "summary",
                                    "root_cause",
                                    "recommendation",
                                    "action_plan",
                                    "expected_outcome",
                                    "monitor",
                                ],

                                "additionalProperties": False,
                            },
                        },
                    },

                    "required": [
                        "insights"
                    ],

                    "additionalProperties": False,
                },
            },
        },
    }

    for attempt in range(retries):

        try:

            response = await _HTTP_CLIENT.post(
                OPENROUTER_URL,
                headers=headers,
                json=payload,
            )

            logger.info(
                "OpenRouter status=%s",
                response.status_code,
            )

            response.raise_for_status()

            data = response.json()

            choices = data.get("choices")

            if not choices:
                raise ValueError(
                    "LLM response does not contain choices."
                )

            message = choices[0].get(
                "message",
                {},
            )

            content = message.get(
                "content"
            )

            if not content:
                raise ValueError(
                    "LLM returned an empty response."
                )

            return content.strip()

        except httpx.HTTPStatusError as e:

            logger.warning(
                "LLM HTTP error attempt %s/%s: %s",
                attempt + 1,
                retries,
                e.response.status_code,
                )

            if attempt == retries - 1:
                raise

            await asyncio.sleep(
                2 ** attempt
            )

        except Exception as e:

            logger.warning(
                "LLM attempt %s/%s failed: %s",
                attempt + 1,
                retries,
                str(e),
                )

            if attempt == retries - 1:
                raise

            await asyncio.sleep(
                2 ** attempt
            )

    raise RuntimeError(
        "LLM request failed after all retries."
    )


# ==========================================================
# BACKEND NUMERICAL CALCULATIONS
# ==========================================================

def calculate_change(
        current: float,
        previous: float | None,
) -> dict:

    if previous is None:

        return {
            "change_value": None,
            "change_percentage": None,
            "trend": "not_comparable",
        }

    change = current - previous

    if change > 0:
        trend = "increasing"

    elif change < 0:
        trend = "decreasing"

    else:
        trend = "stable"

    percentage = None

    if previous != 0:

        percentage = round(
            (change / previous) * 100,
            2,
            )

    return {
        "change_value": round(
            change,
            2,
        ),

        "change_percentage": percentage,

        "trend": trend,
    }


def build_authoritative_metric(
        name: str,
        current: float,
        previous: float | None,
) -> dict:

    comparison = calculate_change(
        current,
        previous,
    )

    return {
        "name": name,

        "current_value": round(
            current,
            2,
        ),

        "previous_value": (
            round(previous, 2)
            if previous is not None
            else None
        ),

        "change_value": comparison[
            "change_value"
        ],

        "change_percentage": comparison[
            "change_percentage"
        ],

        "trend": comparison[
            "trend"
        ],
    }


# ==========================================================
# COLLECT BUSINESS SUMMARY
# ==========================================================

def collect_summary(
        db: Session,
        business: Business,
) -> dict:

    """
    Collect ONLY metrics required for AI insights.

    Numerical calculations are performed by backend.

    Inventory is intentionally NOT included.
    """

    today = datetime.utcnow().date()

    # ------------------------------------------------------
    # Window collector
    # ------------------------------------------------------

    def collect_window(
            start_date,
            end_date,
    ) -> dict:

        sales = db.execute(
            text("""
                SELECT
                    COALESCE(
                        SUM(amount),
                        0
                    ) AS total_sales,

                    COALESCE(
                        COUNT(DISTINCT customer_name),
                        0
                    ) AS total_customers

                FROM sales

                WHERE business_id = :bid

                  AND sale_date::date >= :start_date

                  AND sale_date::date <= :end_date
            """),

            {
                "bid": business.id,
                "start_date": start_date,
                "end_date": end_date,
            },
        ).fetchone()

        expenses = db.execute(
            text("""
                SELECT
                    COALESCE(
                        SUM(amount),
                        0
                    ) AS total_expenses

                FROM expenses

                WHERE business_id = :bid

                  AND expense_date::date >= :start_date

                  AND expense_date::date <= :end_date
            """),

            {
                "bid": business.id,
                "start_date": start_date,
                "end_date": end_date,
            },
        ).fetchone()

        # --------------------------------------------------
        # Backend calculations
        # --------------------------------------------------

        total_sales = float(
            sales.total_sales or 0
        )

        total_expenses = float(
            expenses.total_expenses or 0
        )

        customer_count = int(
            sales.total_customers or 0
        )

        # PROFIT = SALES - EXPENSES
        profit = (
                total_sales
                - total_expenses
        )

        # LOSS = negative profit converted
        # to positive display value
        loss = max(
            -profit,
            0,
        )

        return {
            "total_sales": round(
                total_sales,
                2,
            ),

            "total_expenses": round(
                total_expenses,
                2,
            ),

            "profit": round(
                profit,
                2,
            ),

            "loss": round(
                loss,
                2,
            ),

            "customer_count": customer_count,
        }

    # ======================================================
    # 7 DAYS
    # ======================================================

    current_7_start = (
            today - timedelta(days=6)
    )

    current_7_end = today

    previous_7_start = (
            today - timedelta(days=13)
    )

    previous_7_end = (
            today - timedelta(days=7)
    )

    # ======================================================
    # 30 DAYS
    # ======================================================

    current_30_start = (
            today - timedelta(days=29)
    )

    current_30_end = today

    previous_30_start = (
            today - timedelta(days=59)
    )

    previous_30_end = (
            today - timedelta(days=30)
    )

    # ======================================================
    # FIND FIRST BUSINESS DATA DATE
    # ======================================================

    first_dates = []

    first_sale = db.execute(
        text("""
            SELECT
                MIN(sale_date::date)
            FROM sales
            WHERE business_id = :bid
        """),

        {
            "bid": business.id
        },
    ).scalar()

    if first_sale:
        first_dates.append(
            first_sale
        )

    first_expense = db.execute(
        text("""
            SELECT
                MIN(expense_date::date)
            FROM expenses
            WHERE business_id = :bid
        """),

        {
            "bid": business.id
        },
    ).scalar()

    if first_expense:
        first_dates.append(
            first_expense
        )

    # ======================================================
    # ALL TIME
    # ======================================================

    if first_dates:

        first_data_date = min(
            first_dates
        )

        metrics_all = collect_window(
            first_data_date,
            today,
        )

    else:

        metrics_all = {
            "total_sales": 0,
            "total_expenses": 0,
            "profit": 0,
            "loss": 0,
            "customer_count": 0,
        }

    # ======================================================
    # RETURN BACKEND SUMMARY
    # ======================================================

    return {
        "business_id": business.id,

        "metrics_7d": collect_window(
            current_7_start,
            current_7_end,
        ),

        "previous_metrics_7d": collect_window(
            previous_7_start,
            previous_7_end,
        ),

        "metrics_30d": collect_window(
            current_30_start,
            current_30_end,
        ),

        "previous_metrics_30d": collect_window(
            previous_30_start,
            previous_30_end,
        ),

        "metrics_all": metrics_all,
    }


# ==========================================================
# BACKEND FORMULA
# ==========================================================

def build_formula(
        metric: dict,
) -> dict:

    current = metric[
        "current_value"
    ]

    previous = metric[
        "previous_value"
    ]

    change = metric[
        "change_value"
    ]

    percentage = metric[
        "change_percentage"
    ]

    if previous is None:

        return {
            "name": "Not comparable",

            "expression": "",

            "calculation": "",

            "result": (
                "No previous period available."
            ),
        }

    if percentage is None:

        return {
            "name": "Period Change",

            "expression": (
                "Current Value - Previous Value"
            ),

            "calculation": (
                f"{current} - {previous}"
            ),

            "result": str(change),
        }

    return {
        "name": "Period Change",

        "expression": (
            "Current Value - Previous Value"
        ),

        "calculation": (
            f"{current} - {previous}"
        ),

        "result": (
            f"{change} "
            f"({percentage}%)"
        ),
    }


# ==========================================================
# BACKEND URGENCY
# ==========================================================

def backend_generated_urgency(
        metric: dict,
) -> dict:

    """
    Urgency is determined by backend metric state.

    The LLM does NOT decide numerical urgency.
    """

    trend = metric[
        "trend"
    ]

    percentage = metric[
        "change_percentage"
    ]

    if percentage is None:

        return {
            "level": "low",
            "reason": (
                "There is no comparable previous "
                "period."
            ),
        }

    if trend == "decreasing":

        if abs(percentage) >= 30:

            return {
                "level": "critical",
                "reason": (
                    "The metric decreased by "
                    f"{abs(percentage)}%."
                ),
            }

        if abs(percentage) >= 15:

            return {
                "level": "high",
                "reason": (
                    "The metric decreased by "
                    f"{abs(percentage)}%."
                ),
            }

        if abs(percentage) >= 5:

            return {
                "level": "medium",
                "reason": (
                    "The metric decreased by "
                    f"{abs(percentage)}%."
                ),
            }

    return {
        "level": "low",
        "reason": (
            "The metric does not currently "
            "indicate a severe change."
        ),
    }


# ==========================================================
# BACKEND IMPACT
# ==========================================================

def backend_generated_impact(
        metric: dict,
) -> dict:

    """
    Financial impact is NOT invented by the LLM.

    Since we do not independently calculate revenue
    loss here, financial values remain unavailable.
    """

    trend = metric[
        "trend"
    ]

    percentage = metric[
        "change_percentage"
    ]

    if trend == "decreasing":

        if percentage is not None:

            business_risk = (
                "high"
                if abs(percentage) >= 15
                else "medium"
            )

        else:

            business_risk = "low"

    else:

        business_risk = "low"

    return {
        "financial_value": None,

        "estimated_revenue_loss": None,

        "financial_impact_available": False,

        "financial_impact_reason": (
            "Financial impact was not independently "
            "calculated by the backend."
        ),

        "customer_impact": "",

        "business_risk": business_risk,
    }


# ==========================================================
# GENERATE AI INSIGHTS
# ==========================================================

async def generate_ai_insights_live(
        db: Session,
        summary_data: dict,
        lang="en",
        window=7,
) -> List[AIInsightResponse]:

    # ------------------------------------------------------
    # Select requested window
    # ------------------------------------------------------

    if window == "all":

        metrics = summary_data[
            "metrics_all"
        ]

        previous_metrics = None

    else:

        metrics = summary_data[
            f"metrics_{window}d"
        ]

        previous_metrics = summary_data[
            f"previous_metrics_{window}d"
        ]

    business_id = summary_data[
        "business_id"
    ]

    language_name = LANGUAGE_MAP.get(
        lang,
        "English",
    )

    # ------------------------------------------------------
    # Backend metric definitions
    # ------------------------------------------------------

    metrics_map = {
        "total_sales": "Total Sales",
        "total_expenses": "Total Expenses",
        "profit": "Profit",
        "loss": "Loss",
        "customer_count": "Customer Count",
    }

    metric_data = []

    for key, title in metrics_map.items():

        current_value = float(
            metrics.get(
                key,
                0,
            )
        )

        # ----------------------------------------------
        # ALL TIME
        # ----------------------------------------------

        if window == "all":

            if current_value == 0:
                continue

            metric_data.append(
                build_authoritative_metric(
                    name=title,
                    current=current_value,
                    previous=None,
                )
            )

        # ----------------------------------------------
        # COMPARABLE PERIOD
        # ----------------------------------------------

        else:

            previous_value = float(
                previous_metrics.get(
                    key,
                    0,
                )
            )

            # No useful information
            if (
                    current_value == 0
                    and previous_value == 0
            ):
                continue

            metric_data.append(
                build_authoritative_metric(
                    name=title,
                    current=current_value,
                    previous=previous_value,
                )
            )

    # ------------------------------------------------------
    # NO DATA
    # ------------------------------------------------------

    if not metric_data:

        return [
            AIInsightResponse(
                id=None,

                business_id=business_id,

                title="No Data Available",

                detail=(
                    "Add sales or expense data "
                    "to generate business insights."
                ),

                score=0,

                language=lang,

                extra_data=AIInsightExtraData(
                    metric={
                        "name": "Business Metrics",
                        "current_value": 0,
                        "previous_value": 0,
                        "change_value": 0,
                        "change_percentage": 0,
                        "trend": "stable",
                    },

                    urgency={
                        "level": "low",
                        "reason": (
                            "There is not enough "
                            "business data."
                        ),
                    },

                    root_cause={
                        "primary": (
                            "No business data available."
                        ),
                        "possible_causes": [],
                        "evidence": [],
                        "confidence": 0,
                    },

                    impact={
                        "financial_value": None,
                        "estimated_revenue_loss": None,
                        "financial_impact_available": False,
                        "financial_impact_reason": (
                            "No financial data available."
                        ),
                        "customer_impact": "",
                        "business_risk": "low",
                    },

                    formula={
                        "name": "",
                        "expression": "",
                        "calculation": "",
                        "result": "",
                    },

                    comparison={
                        "previous_period": 0,
                        "current_period": 0,
                        "difference": 0,
                        "percentage_change": 0,
                    },

                    recommendation={
                        "priority": "low",
                        "immediate_actions": [
                            "Add business data."
                        ],
                        "short_term_actions": [],
                        "long_term_actions": [],
                    },

                    action_plan=[
                        {
                            "step": 1,
                            "action": (
                                "Add sales or expense data."
                            ),
                            "priority": "high",
                        }
                    ],

                    expected_outcome=(
                        "Insights will be generated "
                        "once sufficient data is available."
                    ),

                    monitor=[],
                ),

                expanded_detail=(
                    "No insights yet"
                ),
            )
        ]

    # ======================================================
    # RAG CONTEXT
    # ======================================================

    rag_query = """
Find business-specific evidence relevant to these
business metrics:

- Total Sales
- Total Expenses
- Profit
- Loss
- Customer Count

Look for evidence related to:

- sales
- customers
- pricing
- suppliers
- expenses
- business events
- business policies
- business notes
- uploaded reports

Return ONLY information relevant to understanding
these metrics or possible causes of their changes.

Do not retrieve unrelated information.

Evidence is not automatically proof of causation.
"""

    rag_chunks = get_business_context(
        db=db,
        business_id=business_id,
        question=rag_query,
        top_k=10,
        similarity_threshold=0.30,
    )

    if rag_chunks:

        rag_context = "\n\n".join(
            f"Business Context {i + 1}:\n"
            f"{chunk['text']}"
            for i, chunk in enumerate(
                rag_chunks
            )
        )

    else:

        rag_context = (
            "No relevant business context "
            "was found."
        )

    # ======================================================
    # LLM PROMPT
    # ======================================================

    prompt = f"""
You are Udyamix AI.

Analyze the business metrics supplied by the
backend.

==================================================
AUTHORITATIVE BACKEND METRICS
==================================================

These values were calculated by the backend.

They are immutable.

{json.dumps(metric_data, indent=2)}

==================================================
STRICT NUMERICAL RULE
==================================================

DO NOT:

- recalculate numbers
- modify numbers
- round numbers
- calculate percentages
- calculate profit
- calculate loss
- calculate revenue
- calculate customer counts
- create financial losses
- create comparison values
- create formulas

The backend is the ONLY source of truth
for numerical information.

==================================================
BUSINESS CONTEXT
==================================================

{rag_context}

Use this context ONLY as supporting evidence.

Never invent evidence.

==================================================
ROOT CAUSE
==================================================

Only claim a confirmed root cause when the
provided business evidence directly supports it.

Otherwise use:

"Insufficient evidence to determine the root cause."

Possible causes must remain hypotheses.

==================================================
GENERATE
==================================================

For each supplied backend metric generate:

1. metric_name
2. title
3. summary
4. root cause interpretation
5. possible causes
6. evidence
7. confidence
8. recommendations
9. action plan
10. expected outcome
11. monitoring suggestions

You MAY reference the authoritative backend numbers
in the generated text.

If you reference a number, copy it exactly from the
backend metric.

Do not perform any calculation yourself.

The backend will independently attach the authoritative
numerical fields to the final response.

==================================================
LANGUAGE
==================================================

Respond in {language_name}.

==================================================
IMPORTANT
==================================================

Return one insight only for a metric supplied
by the backend.

Do not invent additional metrics.

Return ONLY valid JSON.
"""

    # ======================================================
    # CALL LLM
    # ======================================================

    try:

        raw = await _openai_chat(
            prompt
        )

        if raw.startswith("```"):

            raw = (
                raw.replace(
                    "```json",
                    "",
                )
                .replace(
                    "```",
                    "",
                )
                .strip()
            )

        response_data = json.loads(
            raw
        )

        generated_insights = (
            response_data.get(
                "insights",
                []
            )
        )

    except Exception as e:

        logger.error(
            "AI insight generation failed "
            "for business_id=%s window=%s: %s",
            business_id,
            window,
            str(e),
        )

        return []

    # ======================================================
    # BACKEND ASSEMBLES FINAL RESPONSE
    # ======================================================

    sections = []

    for generated_insight in generated_insights:

        metric_name = generated_insight.get(
            "metric_name"
        )

        # --------------------------------------------------
        # Find backend metric
        # --------------------------------------------------

        backend_metric = next(
            (
                metric
                for metric in metric_data
                if metric["name"]
                   == metric_name
            ),
            None,
        )

        # --------------------------------------------------
        # Never accept unknown metric
        # --------------------------------------------------

        if backend_metric is None:

            logger.warning(
                "LLM returned unknown metric: %s",
                metric_name,
            )

            continue

        # --------------------------------------------------
        # BACKEND-CREATED VALUES
        # --------------------------------------------------

        backend_formula = build_formula(
            backend_metric
        )

        backend_comparison = {
            "previous_period": (
                backend_metric[
                    "previous_value"
                ]
            ),

            "current_period": (
                backend_metric[
                    "current_value"
                ]
            ),

            "difference": (
                backend_metric[
                    "change_value"
                ]
            ),

            "percentage_change": (
                backend_metric[
                    "change_percentage"
                ]
            ),
        }

        backend_urgency = (
            backend_generated_urgency(
                backend_metric
            )
        )

        backend_impact = (
            backend_generated_impact(
                backend_metric
            )
        )

        # --------------------------------------------------
        # LLM QUALITATIVE CONTENT
        # --------------------------------------------------

        generated_root_cause = (
            generated_insight.get(
                "root_cause",
                {},
            )
        )

        generated_recommendation = (
            generated_insight.get(
                "recommendation",
                {},
            )
        )

        generated_action_plan = (
            generated_insight.get(
                "action_plan",
                [],
            )
        )

        # --------------------------------------------------
        # ROOT CAUSE SAFETY
        # --------------------------------------------------

        evidence = generated_root_cause.get(
            "evidence",
            [],
        )

        if not evidence:

            generated_root_cause = {
                "primary": (
                    "Insufficient evidence to "
                    "determine the root cause."
                ),

                "possible_causes": [],

                "evidence": [],

                "confidence": 0,
            }

        # --------------------------------------------------
        # FINAL EXTRA DATA
        # --------------------------------------------------

        extra = AIInsightExtraData(

            metric=backend_metric,

            comparison=backend_comparison,

            formula=backend_formula,

            urgency=backend_urgency,

            root_cause=generated_root_cause,

            impact=backend_impact,

            recommendation=generated_recommendation,

            action_plan=generated_action_plan,

            expected_outcome=(
                generated_insight.get(
                    "expected_outcome",
                    "",
                )
            ),

            monitor=(
                generated_insight.get(
                    "monitor",
                    [],
                )
            ),
        )

        # --------------------------------------------------
        # FINAL RESPONSE OBJECT
        # --------------------------------------------------

        insight = AIInsightResponse(

            id=None,

            business_id=business_id,

            title=(
                generated_insight.get(
                    "title",
                    f"{metric_name} Insight",
                )
            ),

            detail=(
                generated_insight.get(
                    "summary",
                    "",
                )
            ),

            score=int(
                generated_root_cause.get(
                    "confidence",
                    0,
                )
                * 100
            ),

            language=lang,

            extra_data=extra,

            expanded_detail=(
                generated_insight.get(
                    "summary",
                    "",
                )
            ),
        )

        sections.append(
            insight
        )

    return sections


# ==========================================================
# MODEL TO DICT
# ==========================================================

def model_to_dict(obj):

    if obj is None:
        return None

    if hasattr(
            obj,
            "model_dump",
    ):
        return obj.model_dump()

    if hasattr(
            obj,
            "dict",
    ):
        return obj.dict()

    if isinstance(
            obj,
            dict,
    ):
        return obj

    return obj


# ==========================================================
# VERIFY GENERATED INSIGHTS
# ==========================================================

def verify_generated_insights(
        insights: List[AIInsightResponse],
        summary_data: dict,
        window=7,
) -> List[AIInsightResponse]:

    """
    Final safety/validation layer.

    Architecture:

        DATABASE
           ↓
        BACKEND CALCULATION
           ↓
        AUTHORITATIVE METRICS
           ↓
        LLM INTERPRETATION
           ↓
        BACKEND REASSEMBLES RESPONSE
           ↓
        VERIFICATION
           ↓
        CLIENT
    """

    verified_insights = []

    allowed_levels = {
        "low",
        "medium",
        "high",
        "critical",
    }

    metric_names = {
        "Total Sales",
        "Total Expenses",
        "Profit",
        "Loss",
        "Customer Count",
    }

    for insight in insights:

        try:

            # ==================================================
            # BASIC VALIDATION
            # ==================================================

            if not isinstance(
                    insight,
                    AIInsightResponse,
            ):
                continue

            if not insight.title:
                continue

            if not insight.detail:
                continue

            if insight.extra_data is None:
                continue

            extra = insight.extra_data

            # ==================================================
            # METRIC
            # ==================================================

            metric = extra.metric

            if not metric:
                continue

            metric_dict = model_to_dict(
                metric
            )

            metric_name = metric_dict.get(
                "name"
            )

            if metric_name not in metric_names:
                continue

            # ==================================================
            # REQUIRED BACKEND NUMBERS
            # ==================================================

            required_metric_fields = [
                "name",
                "current_value",
                "previous_value",
                "change_value",
                "change_percentage",
                "trend",
            ]

            if any(
                    field not in metric_dict
                    for field in required_metric_fields
            ):
                continue

            # ==================================================
            # ROOT CAUSE
            # ==================================================

            root_cause = extra.root_cause

            if not root_cause:
                continue

            root_cause_dict = model_to_dict(
                root_cause
            )

            primary = root_cause_dict.get(
                "primary",
                "",
            )

            evidence = root_cause_dict.get(
                "evidence",
                [],
            )

            possible_causes = (
                root_cause_dict.get(
                    "possible_causes",
                    [],
                )
            )

            confidence = root_cause_dict.get(
                "confidence",
                0,
            )

            if not isinstance(
                    primary,
                    str,
            ):
                continue

            if not isinstance(
                    evidence,
                    list,
            ):
                continue

            if not isinstance(
                    possible_causes,
                    list,
            ):
                continue

            try:
                confidence = float(
                    confidence
                )
            except (
                    TypeError,
                    ValueError,
            ):
                continue

            if not 0 <= confidence <= 1:
                continue

            # --------------------------------------------------
            # No evidence = no confirmed cause
            # --------------------------------------------------

            if not evidence:

                root_cause.primary = (
                    "Insufficient evidence to "
                    "determine the root cause."
                )

                root_cause.possible_causes = []

                root_cause.confidence = 0.0

            # ==================================================
            # IMPACT
            # ==================================================

            impact = extra.impact

            if not impact:
                continue

            # LLM must NEVER provide financial impact.
            # Backend always owns these values.

            impact.financial_value = None

            impact.estimated_revenue_loss = None

            impact.financial_impact_available = False

            impact.financial_impact_reason = (
                "Financial impact was not independently "
                "calculated by the backend."
            )

            # ==================================================
            # URGENCY
            # ==================================================

            urgency = extra.urgency

            if not urgency:
                continue

            urgency_level = urgency.level

            if not isinstance(
                    urgency_level,
                    str,
            ):
                continue

            urgency_level = (
                urgency_level
                .strip()
                .lower()
            )

            if urgency_level not in allowed_levels:
                continue

            # Keep normalized value
            urgency.level = urgency_level

            # ==================================================
            # BUSINESS RISK
            # ==================================================

            business_risk = impact.business_risk

            if not isinstance(
                    business_risk,
                    str,
            ):
                continue

            business_risk = (
                business_risk
                .strip()
                .lower()
            )

            if business_risk not in allowed_levels:
                continue

            # Keep normalized value
            impact.business_risk = business_risk

            # ==================================================
            # RECOMMENDATION
            # ==================================================

            recommendation = (
                extra.recommendation
            )

            if not recommendation:
                continue

            recommendation_dict = (
                model_to_dict(
                    recommendation
                )
            )

            priority = (
                recommendation_dict.get(
                    "priority"
                )
            )

            if not isinstance(
                    priority,
                    str,
            ):
                continue

            priority = (
                priority
                .strip()
                .lower()
            )

            if priority not in allowed_levels:
                continue

            # Keep normalized value
            recommendation.priority = priority

            # --------------------------------------------------
            # Recommendation actions
            # --------------------------------------------------

            for action_field in [
                "immediate_actions",
                "short_term_actions",
                "long_term_actions",
            ]:

                actions = (
                    recommendation_dict.get(
                        action_field,
                        [],
                    )
                )

                if not isinstance(
                        actions,
                        list,
                ):
                    raise ValueError(
                        f"{action_field} must be a list."
                    )

                if not all(
                        isinstance(
                            action,
                            str,
                        )
                        for action in actions
                ):
                    raise ValueError(
                        f"{action_field} must "
                        "contain strings."
                    )

            # ==================================================
            # ACTION PLAN
            # ==================================================

            action_plan = extra.action_plan

            if not isinstance(
                    action_plan,
                    list,
            ):
                continue

            for action in action_plan:

                action_dict = model_to_dict(
                    action
                )

                if not isinstance(
                        action_dict,
                        dict,
                ):
                    continue

                if not action_dict.get(
                        "action"
                ):
                    continue

                action_priority = (
                    action_dict.get(
                        "priority"
                    )
                )

                if not isinstance(
                        action_priority,
                        str,
                ):
                    continue

                action_priority = (
                    action_priority
                    .strip()
                    .lower()
                )

                if action_priority not in allowed_levels:
                    continue

                # Keep normalized value
                action.priority = action_priority

            # ==================================================
            # COMPARISON
            # ==================================================

            comparison = extra.comparison

            if not comparison:
                continue

            comparison_dict = model_to_dict(
                comparison
            )

            required_comparison_fields = [
                "previous_period",
                "current_period",
                "difference",
                "percentage_change",
            ]

            if any(
                    field not in comparison_dict
                    for field in required_comparison_fields
            ):
                continue

            # ==================================================
            # FORMULA
            # ==================================================

            formula = extra.formula

            if not formula:
                continue

            formula_dict = model_to_dict(
                formula
            )

            required_formula_fields = [
                "name",
                "expression",
                "calculation",
                "result",
            ]

            if any(
                    field not in formula_dict
                    for field in required_formula_fields
            ):
                continue

            # ==================================================
            # VERIFIED
            # ==================================================

            logger.info(
                "AI insight verified: "
                "business_id=%s metric=%s window=%s",
                summary_data["business_id"],
                metric_name,
                window,
            )

            verified_insights.append(
                insight
            )

        except Exception as e:

            logger.error(
                "Insight verification error: %s",
                str(e),
            )

            continue

    logger.info(
        "AI insight verification completed: "
        "%s/%s verified.",
        len(verified_insights),
        len(insights),
    )

    return verified_insights


# ==========================================================
# FETCH AI INSIGHTS
# ==========================================================

async def fetch_ai_insights(
        db: Session,
        business: Business,
        lang="en",
        window=7,
):

    now = datetime.utcnow()

    cache_key = (
        f"{window}:{lang}"
    )

    cache = (
        _AI_INSIGHTS_CACHE
        .get(
            business.id,
            {},
        )
        .get(
            cache_key
        )
    )

    # ------------------------------------------------------
    # Cache duration
    # ------------------------------------------------------

    if window == "all":

        cache_duration = timedelta(
            days=1
        )

    else:

        cache_duration = timedelta(
            days=window
        )

    # ------------------------------------------------------
    # Generate fresh insights
    # ------------------------------------------------------

    if (
            not cache
            or (
            now - cache["timestamp"]
    ) > cache_duration
    ):

        # Backend calculates everything
        summary = collect_summary(
            db,
            business,
        )

        # LLM interprets backend values
        insights = (
            await generate_ai_insights_live(
                db=db,
                summary_data=summary,
                lang=lang,
                window=window,
            )
        )

        # Final backend verification
        verified_insights = (
            verify_generated_insights(
                insights=insights,
                summary_data=summary,
                window=window,
            )
        )

        # --------------------------------------------------
        # Cache ONLY verified insights
        # --------------------------------------------------

        _AI_INSIGHTS_CACHE.setdefault(
            business.id,
            {},
        )[cache_key] = {
            "timestamp": now,
            "insights": verified_insights,
        }

        return verified_insights

    return cache["insights"]