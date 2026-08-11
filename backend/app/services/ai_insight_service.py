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
from ..models.ai_insight_model import AIInsight
from ..schemas.ai_insight_schema import (
    AIInsightResponse,
    AIInsightExtraData,
)
from ..rag.service import get_business_context


load_dotenv()
logger = logging.getLogger("ai_insight_service")

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"

LANGUAGE_MAP = {
    "en": "English", "hi": "Hindi", "ta": "Tamil", "te": "Telugu",
    "mr": "Marathi", "bn": "Bengali", "gu": "Gujarati", "kn": "Kannada",
    "ml": "Malayalam", "pa": "Punjabi", "or": "Odia", "as": "Assamese",
    "ur": "Urdu", "ks": "Kashmiri", "kok": "Konkani", "sd": "Sindhi",
    "mni": "Manipuri", "ne": "Nepali", "sa": "Sanskrit", "brx": "Bodo",
    "sat": "Santhali", "mai": "Maithili", "doi": "Dogri",
}

_AI_INSIGHTS_CACHE = {}


async def _openai_chat(prompt: str, retries: int = 3) -> str:
    async with httpx.AsyncClient(timeout=60) as client:
        for attempt in range(retries):
            try:
                response = await client.post(
                    OPENROUTER_URL,
                    headers={
                        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": "openai/gpt-4o-mini",
                        "messages": [
                            {
                                "role": "system",
                                "content": (
                                    "You are Udyamix AI, an intelligent business analyst. "
                                    "Return ONLY valid JSON. Do not invent business facts. "
                                    "Use retrieved business context only when relevant. "
                                    "Numerical calculations provided by the system must be preserved."
                                ),
                            },
                            {"role": "user", "content": prompt},
                        ],
                        "temperature": 0.1,
                    },
                )

                response.raise_for_status()
                return response.json()["choices"][0]["message"]["content"]

            except Exception as e:
                logger.warning(f"LLM retry {attempt + 1} failed: {e}")

                if attempt == retries - 1:
                    raise

                await asyncio.sleep(1)


def calculate_change(current: float, previous: float) -> dict:
    change = current - previous
    percentage = (change / previous) * 100 if previous != 0 else 0

    if change > 0:
        trend = "increasing"
    elif change < 0:
        trend = "decreasing"
    else:
        trend = "stable"

    return {
        "current_value": round(current, 2),
        "previous_value": round(previous, 2),
        "change_value": round(change, 2),
        "change_percentage": round(percentage, 2),
        "trend": trend,
    }


def collect_summary(db: Session, business: Business) -> dict:
    today = datetime.utcnow().date()

    def collect_window(start_date, end_date) -> dict:
        sales = db.execute(
            text("""
                SELECT
                    COALESCE(SUM(amount), 0) AS total_sales,
                    COALESCE(COUNT(DISTINCT customer_name), 0) AS total_customers
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
                SELECT COALESCE(SUM(amount), 0) AS total_expenses
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

        try:
            inv = db.execute(
                text("""
                    SELECT
                        COALESCE(SUM(quantity::numeric), 0) AS total_qty,
                        COALESCE(
                            SUM(quantity::numeric * price_per_unit),
                            0
                        ) AS total_value
                    FROM inventories
                    WHERE business_id = :bid
                """),
                {"bid": business.id},
            ).fetchone()

            inventory_quantity = float(inv.total_qty or 0)
            inventory_value = float(inv.total_value or 0)

        except Exception as e:
            logger.warning(f"Inventory query failed: {e}")
            inventory_quantity = 0
            inventory_value = 0

        total_sales = float(sales.total_sales or 0)
        total_expenses = float(expenses.total_expenses or 0)
        profit = total_sales - total_expenses

        return {
            "total_sales": round(total_sales, 2),
            "total_expenses": round(total_expenses, 2),
            "profit": round(profit, 2),
            "loss": round(max(-profit, 0), 2),
            "customer_count": int(sales.total_customers or 0),
            "inventory_quantity": round(inventory_quantity, 2),
            "inventory_value": round(inventory_value, 2),
        }

    current_7_start = today - timedelta(days=6)
    current_7_end = today
    previous_7_start = today - timedelta(days=13)
    previous_7_end = today - timedelta(days=7)

    current_30_start = today - timedelta(days=29)
    current_30_end = today
    previous_30_start = today - timedelta(days=59)
    previous_30_end = today - timedelta(days=30)

    return {
        "business_id": business.id,
        "metrics_7d": collect_window(current_7_start, current_7_end),
        "previous_metrics_7d": collect_window(previous_7_start, previous_7_end),
        "metrics_30d": collect_window(current_30_start, current_30_end),
        "previous_metrics_30d": collect_window(previous_30_start, previous_30_end),
    }


async def generate_ai_insights_live(
        db: Session,
        summary_data: dict,
        lang="en",
        window=7,
) -> List[AIInsightResponse]:

    metrics = summary_data[f"metrics_{window}d"]
    previous_metrics = summary_data[f"previous_metrics_{window}d"]
    business_id = summary_data["business_id"]
    language_name = LANGUAGE_MAP.get(lang, "English")

    metrics_map = {
        "total_sales": "Total Sales",
        "total_expenses": "Total Expenses",
        "profit": "Profit",
        "loss": "Loss",
        "customer_count": "Customer Count",
        "inventory_quantity": "Inventory Quantity",
        "inventory_value": "Inventory Value",
    }

    sections = []

    for key, title in metrics_map.items():
        current_value = float(metrics.get(key, 0))
        previous_value = float(previous_metrics.get(key, 0))

        if current_value == 0 and previous_value == 0:
            continue

        comparison = calculate_change(current_value, previous_value)

        rag_query = f"""
Analyze business information related to:

Metric: {title}
Current value: {current_value}
Previous value: {previous_value}
Change: {comparison["change_value"]}
Change percentage: {comparison["change_percentage"]}%
Trend: {comparison["trend"]}

Find business-specific information that may explain this metric,
including relevant policies, products, pricing, supplier information,
customer information, reports, business notes, uploaded documents,
or other business knowledge.
"""

        try:
            rag_chunks = get_business_context(
                db=db,
                business_id=business_id,
                question=rag_query,
                top_k=5,
                similarity_threshold=0.30,
            )
        except Exception as e:
            logger.warning(f"RAG retrieval failed for {title}: {e}")
            rag_chunks = []

        if rag_chunks:
            rag_context = "\n\n".join(
                f"Business Context {i + 1}:\n{chunk['text']}"
                for i, chunk in enumerate(rag_chunks)
            )
        else:
            rag_context = "No relevant business context was found."

        if previous_value != 0:
            formula_expression = "(Current - Previous) / Previous × 100"
            formula_calculation = (
                f"({current_value} - {previous_value}) / "
                f"{previous_value} × 100"
            )
            formula_result = f"{comparison['change_percentage']}%"
        else:
            formula_expression = (
                "Previous value is zero; percentage change "
                "cannot be calculated normally."
            )
            formula_calculation = "Not applicable"
            formula_result = "Not available"

        prompt = f"""
You are Udyamix AI Business Analyst.

Analyze one business metric using:

1. Actual business data
2. Previous-period business data
3. Calculated comparison
4. Retrieved business-specific RAG context

BUSINESS ID:
{business_id}

METRIC:
Name: {title}
Current value: {current_value}
Previous value: {previous_value}
Change: {comparison["change_value"]}
Change percentage: {comparison["change_percentage"]}%
Trend: {comparison["trend"]}

FORMULA:
Expression: {formula_expression}
Calculation: {formula_calculation}
Result: {formula_result}

BUSINESS CONTEXT FROM RAG:
{rag_context}

IMPORTANT RULES:

1. Analyze the actual numbers.
2. Use RAG information only when relevant.
3. Do NOT invent business-specific facts.
4. If RAG does not contain evidence for a root cause, explicitly
   state that the root cause is uncertain.
5. Distinguish between confirmed evidence, possible causes,
   and assumptions.
6. The numerical comparison values provided by the system must
   not be changed.
7. Give practical recommendations.
8. Recommendations should be realistic for a small or medium business.
9. Generate immediate, short-term and long-term actions.
10. Return ONLY valid JSON.
11. Use the requested language: {language_name}

RETURN EXACTLY THIS STRUCTURE:

{{
    "title": "...",
    "summary": "...",
    "metric": {{
        "name": "{title}",
        "current_value": {current_value},
        "previous_value": {previous_value},
        "change_value": {comparison["change_value"]},
        "change_percentage": {comparison["change_percentage"]},
        "trend": "{comparison["trend"]}"
    }},
    "urgency": {{
        "level": "low",
        "reason": "..."
    }},
    "root_cause": {{
        "primary": "...",
        "possible_causes": ["..."],
        "evidence": ["..."],
        "confidence": 0.0
    }},
    "impact": {{
        "financial_value": 0,
        "estimated_revenue_loss": 0,
        "customer_impact": "...",
        "business_risk": "low"
    }},
    "formula": {{
        "name": "{title} Change Percentage",
        "expression": "{formula_expression}",
        "calculation": "{formula_calculation}",
        "result": "{formula_result}"
    }},
    "comparison": {{
        "previous_period": {previous_value},
        "current_period": {current_value},
        "difference": {comparison["change_value"]},
        "percentage_change": {comparison["change_percentage"]}
    }},
    "recommendation": {{
        "priority": "medium",
        "immediate_actions": ["..."],
        "short_term_actions": ["..."],
        "long_term_actions": ["..."]
    }},
    "action_plan": [
        {{
            "step": 1,
            "action": "...",
            "priority": "high"
        }}
    ],
    "expected_outcome": "...",
    "monitor": ["..."]
}}
"""

        try:
            raw = await _openai_chat(prompt)

            if raw.startswith("```"):
                raw = (
                    raw.replace("```json", "")
                    .replace("```", "")
                    .strip()
                )

            sec = json.loads(raw)

            extra = {
                "metric": sec.get("metric", comparison),
                "urgency": sec.get(
                    "urgency",
                    {"level": "low", "reason": ""},
                ),
                "root_cause": sec.get(
                    "root_cause",
                    {
                        "primary": "",
                        "possible_causes": [],
                        "evidence": [],
                        "confidence": 0,
                    },
                ),
                "impact": sec.get(
                    "impact",
                    {
                        "financial_value": 0,
                        "estimated_revenue_loss": 0,
                        "customer_impact": "",
                        "business_risk": "low",
                    },
                ),
                "formula": sec.get(
                    "formula",
                    {
                        "name": "",
                        "expression": "",
                        "calculation": "",
                        "result": "",
                    },
                ),
                "comparison": sec.get(
                    "comparison",
                    {
                        "previous_period": previous_value,
                        "current_period": current_value,
                        "difference": comparison["change_value"],
                        "percentage_change": comparison["change_percentage"],
                    },
                ),
                "recommendation": sec.get(
                    "recommendation",
                    {
                        "priority": "medium",
                        "immediate_actions": [],
                        "short_term_actions": [],
                        "long_term_actions": [],
                    },
                ),
                "action_plan": sec.get("action_plan", []),
                "expected_outcome": sec.get("expected_outcome", ""),
                "monitor": sec.get("monitor", []),
            }

            insight = AIInsight(
                business_id=business_id,
                insight_type="metric",
                title=sec.get("title", title),
                detail=sec.get("summary", ""),
                score=float(abs(comparison["change_percentage"])),
                language=lang,
                extra_data=json.dumps(extra),
                created_at=datetime.utcnow(),
            )

            db.add(insight)
            db.commit()
            db.refresh(insight)

            sections.append(
                AIInsightResponse(
                    id=insight.id,
                    business_id=business_id,
                    title=insight.title,
                    detail=insight.detail,
                    score=insight.score,
                    language=lang,
                    extra_data=AIInsightExtraData(**extra),
                    expanded_detail=f"{title}: {current_value}",
                )
            )

        except Exception as e:
            logger.error(f"AI insight error for {title}: {e}")

    if not sections:
        return [
            AIInsightResponse(
                id=None,
                business_id=business_id,
                title="No Data Available",
                detail=(
                    "Add sales, expenses or inventory data "
                    "to generate insights."
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
                        "reason": "There is not enough business data.",
                    },
                    root_cause={
                        "primary": "No business data available.",
                        "possible_causes": [],
                        "evidence": [],
                        "confidence": 0,
                    },
                    impact={
                        "financial_value": 0,
                        "estimated_revenue_loss": 0,
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
                        "immediate_actions": ["Add business data."],
                        "short_term_actions": [],
                        "long_term_actions": [],
                    },
                    action_plan=[
                        {
                            "step": 1,
                            "action": (
                                "Add sales, expense or inventory data."
                            ),
                            "priority": "high",
                        }
                    ],
                    expected_outcome=(
                        "Insights will be generated once "
                        "sufficient data is available."
                    ),
                    monitor=[],
                ),
                expanded_detail="No insights yet",
            )
        ]

    return sections


async def fetch_ai_insights(
        db: Session,
        business: Business,
        lang="en",
        window=7,
):
    now = datetime.utcnow()

    cache = (
        _AI_INSIGHTS_CACHE
        .get(business.id, {})
        .get(str(window))
    )

    if (
            not cache
            or (now - cache["timestamp"]) > timedelta(days=window)
    ):
        summary = collect_summary(db, business)

        insights = await generate_ai_insights_live(
            db,
            summary,
            lang,
            window,
        )

        _AI_INSIGHTS_CACHE.setdefault(
            business.id,
            {},
        )[str(window)] = {
            "timestamp": now,
            "insights": insights,
        }

        return insights

    return cache["insights"]
