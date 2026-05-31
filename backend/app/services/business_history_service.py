# app/services/business_history_service.py

from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from collections import defaultdict
import os, json, logging, re
from fastapi.concurrency import run_in_threadpool
from google import genai

from ..models.sales_model import Sale
from ..models.expense_model import Expense
from ..models.inventory_model import Inventory
from ..models.cash_flow_model import CashFlow
from ..models.business_model import Business

# ----------------------------
# Logging
# ----------------------------
logger = logging.getLogger("business_history_service")
logger.setLevel(logging.INFO)

# ----------------------------
# 22 Indian Languages Map
# ----------------------------
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

# ----------------------------
# Gemini AI setup
# ----------------------------
GEMINI_KEY = os.getenv("GEMINI_API_KEY")
client = genai.Client(api_key=GEMINI_KEY)
MODEL_NAME = "gemini-1.5-flash"


# ----------------------------
# Language Detector (simple + safe)
# ----------------------------
def detect_language(text: str) -> str:
    if re.search(r'[\u0900-\u097F]', text):
        return "hi"
    if re.search(r'[\u0B80-\u0BFF]', text):
        return "ta"
    if re.search(r'[\u0C00-\u0C7F]', text):
        return "te"
    return "en"


# ----------------------------
# Clean JSON extractor
# ----------------------------
def extract_json(text: str):
    try:
        return json.loads(text)
    except:
        match = re.search(r"\{.*\}", text, re.DOTALL)
        if match:
            return json.loads(match.group())
        raise


# ----------------------------
# Main function
# ----------------------------
async def get_historical_summary(
        db: Session,
        business: Business,
        period: str,
        lang: str
):

    now = datetime.utcnow()

    if period == "daily":
        start = now - timedelta(days=1)
        group_by = "hour"
    elif period == "weekly":
        start = now - timedelta(weeks=1)
        group_by = "day"
    else:
        start = now - timedelta(days=30)
        group_by = "week"

    sales = db.query(Sale).filter(Sale.business_id == business.id, Sale.sale_date >= start).all()
    expenses = db.query(Expense).filter(Expense.business_id == business.id, Expense.expense_date >= start).all()
    cashflows = db.query(CashFlow).filter(CashFlow.business_id == business.id).all()
    inventory = db.query(Inventory).filter(Inventory.business_id == business.id).all()

    total_sales = sum(s.amount for s in sales)
    total_expenses = sum(e.amount for e in expenses)
    net_cashflow = sum(c.cash_in - c.cash_out for c in cashflows)

    stock_levels = {i.product_name: i.quantity for i in inventory}

    cash_sales = sum(s.amount for s in sales if s.is_paid)
    mostly_cash = (cash_sales / total_sales > 0.7) if total_sales > 0 else False

    sales_trend = defaultdict(float)
    expenses_trend = defaultdict(float)
    cashflow_trend = defaultdict(float)

    def get_key(date):
        return date.strftime("%Y-%m-%d") if group_by != "hour" else date.strftime("%Y-%m-%d %H")

    for s in sales:
        sales_trend[get_key(s.sale_date)] += s.amount

    for e in expenses:
        expenses_trend[get_key(e.expense_date)] += e.amount

    for c in cashflows:
        cashflow_trend[get_key(c.date)] += (c.cash_in - c.cash_out)

    raw_summary = {
        "period": period,
        "total_sales": total_sales,
        "total_expenses": total_expenses,
        "net_cashflow": net_cashflow,
        "mostly_cash": mostly_cash,
        "inventory": stock_levels,
        "sales_trend": dict(sales_trend),
        "expenses_trend": dict(expenses_trend),
        "cashflow_trend": dict(cashflow_trend)
    }

    # ----------------------------
    # Language validation
    # ----------------------------
    language_name = LANGUAGE_MAP.get(lang)
    if not language_name:
        raise ValueError(f"Unsupported language: {lang}")

    # ----------------------------
    # DEEP ANALYTICAL PROMPT
    # ----------------------------
    prompt = f"""
You are an expert financial and business strategist with deep analytical thinking.

STRICT RULES:
- Respond ONLY in {language_name}
- Output ONLY valid JSON (no text, no explanation)
- Do NOT mix languages
- Be precise, insightful, and deeply analytical
- Provide real business intelligence, not generic advice

ANALYZE:
- Profitability trends
- Expense patterns
- Cash flow health
- Inventory risks
- Financial inefficiencies
- Growth opportunities

OUTPUT FORMAT:
{{
  "trends": "Deep analysis of financial trends with reasoning",
  "inventory_advice": "Strategic inventory insights with risk analysis",
  "cash_advice": "Cash flow health + improvements + warnings",
  "recommendations": [
    "Actionable, data-driven recommendation 1",
    "Actionable, data-driven recommendation 2"
  ]
}}

DATA:
{json.dumps(raw_summary, default=str)}
"""

    max_retries = 2
    ai_output = None

    try:
        for attempt in range(max_retries):

            response = await run_in_threadpool(
                lambda: client.models.generate_content(
                    model=MODEL_NAME,
                    contents=prompt
                ).text
            )

            clean = response.strip()

            if clean.startswith("```"):
                clean = clean.replace("```json", "").replace("```", "").strip()

            try:
                ai_output = extract_json(clean)
            except:
                ai_output = None

            if ai_output:
                detected_lang = detect_language(clean)

                if detected_lang == lang or lang == "en":
                    break
                else:
                    logger.warning(f"Lang mismatch: expected {lang}, got {detected_lang}")

            if attempt == max_retries - 1:
                raise Exception("Failed after retries")

        ai_output.setdefault("trends", "")
        ai_output.setdefault("inventory_advice", "")
        ai_output.setdefault("cash_advice", "")
        ai_output.setdefault("recommendations", [])

    except Exception as e:
        logger.error(f"[AI ERROR] {e}")

        ai_output = {
            "trends": "Analysis unavailable",
            "inventory_advice": "Monitor stock levels carefully",
            "cash_advice": "Maintain healthy cash flow",
            "recommendations": []
        }

    return {
        "raw_summary": raw_summary,
        "ai_summary": ai_output,
        "language": lang
    }

