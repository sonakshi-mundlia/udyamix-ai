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
from ..schemas.ai_insight_schema import AIInsightResponse, AIInsightExtraData

load_dotenv()
logger = logging.getLogger("ai_insight_service")
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")

# -------------------- Language Map --------------------
LANGUAGE_MAP = {
    "en": "English", "hi": "Hindi", "ta": "Tamil", "te": "Telugu",
    "mr": "Marathi", "bn": "Bengali", "gu": "Gujarati", "kn": "Kannada",
    "ml": "Malayalam", "pa": "Punjabi", "or": "Odia", "as": "Assamese",
    "ur": "Urdu", "ks": "Kashmiri", "kok": "Konkani", "sd": "Sindhi",
    "mni": "Manipuri", "ne": "Nepali", "sa": "Sanskrit", "brx": "Bodo",
    "sat": "Santhali", "mai": "Maithili", "doi": "Dogri",
}

# -------------------- Cache --------------------
_AI_INSIGHTS_CACHE = {}

# -------------------- OpenRouter --------------------
async def _openai_chat(prompt: str, retries: int = 3) -> str:
    async with httpx.AsyncClient(timeout=60) as client:
        for attempt in range(retries):
            try:
                resp = await client.post(
                    "https://openrouter.ai/api/v1/chat/completions",
                    headers={
                        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": "openai/gpt-4o-mini",
                        "messages": [
                            {"role": "system",
                             "content": "Return STRICT JSON. action_plan must be list of strings."},
                            {"role": "user", "content": prompt},
                        ],
                        "temperature": 0.1,
                    },
                )
                resp.raise_for_status()
                return resp.json()["choices"][0]["message"]["content"]

            except Exception as e:
                logger.warning(f"Retry {attempt+1} failed: {e}")
                if attempt == retries - 1:
                    raise
                await asyncio.sleep(1)

# -------------------- Summary --------------------
def collect_summary(db: Session, business: Business) -> dict:
    today = datetime.utcnow().date()

    def collect_window(window: int) -> dict:
        start_date = today - timedelta(days=window)

        # SALES
        sales = db.execute(text("""
            SELECT COALESCE(SUM(amount),0) total_sales,
                   COALESCE(COUNT(DISTINCT customer_name),0) total_customers
            FROM sales
            WHERE business_id=:bid AND sale_date::date >= :start_date
        """), {"bid": business.id, "start_date": start_date}).fetchone()

        # EXPENSES
        expenses = db.execute(text("""
            SELECT COALESCE(SUM(amount),0) total_expenses
            FROM expenses
            WHERE business_id=:bid AND expense_date::date >= :start_date
        """), {"bid": business.id, "start_date": start_date}).fetchone()

        # INVENTORY (SAFE)
        try:
            inv = db.execute(text("""
                SELECT 
                    COALESCE(SUM(quantity::numeric),0) total_qty,
                    COALESCE(SUM(quantity::numeric * price_per_unit),0) total_value
                FROM inventories
                WHERE business_id=:bid
            """), {"bid": business.id}).fetchone()

            inv_qty = float(inv.total_qty or 0)
            inv_val = float(inv.total_value or 0)

        except Exception as e:
            logger.warning(f"Inventory failed: {e}")
            inv_qty, inv_val = 0, 0

        total_sales = float(sales.total_sales or 0)
        total_expenses = float(expenses.total_expenses or 0)

        profit = max(total_sales - total_expenses, 0)
        loss = max(total_expenses - total_sales, 0)

        return {
            "total_sales": total_sales,
            "total_expenses": total_expenses,
            "profit": round(profit, 2),
            "loss": round(loss, 2),
            "customer_count": int(sales.total_customers or 0),
            "inventory_quantity": round(inv_qty, 2),
            "inventory_value": round(inv_val, 2)
        }

    return {
        "business_id": business.id,
        "metrics_7d": collect_window(7),
        "metrics_30d": collect_window(30)
    }

# -------------------- Generate Insights --------------------
async def generate_ai_insights_live(
        db: Session, summary_data: dict, lang="en", window=7
) -> List[AIInsightResponse]:

    metrics = summary_data[f"metrics_{window}d"]
    language_name = LANGUAGE_MAP.get(lang, "English")

    metrics_map = {
        "total_sales": "Total Sales",
        "total_expenses": "Total Expenses",
        "profit": "Profit",
        "loss": "Loss",
        "customer_count": "Customer Count",
        "inventory_quantity": "Inventory Quantity",
        "inventory_value": "Inventory Value"
    }

    sections = []

    for key, title in metrics_map.items():
        value = metrics.get(key, 0)

        # ✅ skip empty
        if value is None or value <= 0:
            continue

        prompt = f"""
Analyze:
{title} = {value}

Return JSON:
{{"title":"{title}","summary_sentence":"...","urgency":"low",
"root_cause":"...","impact_value":0,"formula":"","action_plan":["step1","step2"]}}

Language: {language_name}
"""

        try:
            raw = await _openai_chat(prompt)

            if raw.startswith("```"):
                raw = raw.replace("```json", "").replace("```", "").strip()

            sec = json.loads(raw)

            # 🔥 FIX action_plan
            action_plan = []
            for item in sec.get("action_plan", []):
                if isinstance(item, str):
                    action_plan.append(item)
                elif isinstance(item, dict):
                    action_plan.append(item.get("step", str(item)))

            extra = {
                "urgency": sec.get("urgency", "low"),
                "root_cause": sec.get("root_cause", ""),
                "impact_value": float(sec.get("impact_value", 0)),
                "formula": sec.get("formula", ""),
                "action_plan": action_plan,
                "metric_value": value
            }

            insight = AIInsight(
                business_id=summary_data["business_id"],
                insight_type="metric",
                title=sec["title"],
                detail=sec.get("summary_sentence", ""),
                score=metrics.get("profit", 0),
                language=lang,
                extra_data=json.dumps(extra),
                created_at=datetime.utcnow()
            )

            db.add(insight)
            db.commit()
            db.refresh(insight)

            sections.append(
                AIInsightResponse(
                    id=insight.id,
                    business_id=insight.business_id,
                    title=insight.title,
                    detail=insight.detail,
                    score=insight.score,
                    language=insight.language,
                    extra_data=AIInsightExtraData(**extra),
                    expanded_detail=f"{title}: {value}"
                )
            )

        except Exception as e:
            logger.error(f"AI error {title}: {e}")

    # NO DATA
    if not sections:
        return [
            AIInsightResponse(
                id=None,
                business_id=summary_data["business_id"],
                title="No Data Available",
                detail="Add sales, expenses or inventory",
                score=0,
                language=lang,
                extra_data=AIInsightExtraData(
                    urgency="low",
                    root_cause="No data",
                    impact_value=0,
                    formula="",
                    action_plan=["Add data to see insights"]
                ),
                expanded_detail="No insights yet"
            )
        ]

    return sections

# -------------------- Fetch --------------------
async def fetch_ai_insights(db: Session, business: Business, lang="en", window=7):
    now = datetime.utcnow()

    cache = _AI_INSIGHTS_CACHE.get(business.id, {}).get(str(window))

    if not cache or (now - cache["timestamp"]) > timedelta(days=window):
        summary = collect_summary(db, business)

        insights = await generate_ai_insights_live(db, summary, lang, window)

        _AI_INSIGHTS_CACHE.setdefault(business.id, {})[str(window)] = {
            "timestamp": now,
            "insights": insights
        }

        return insights

    return cache["insights"]