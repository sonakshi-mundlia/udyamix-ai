import os
import json
import logging
from datetime import datetime, date
from dateutil.parser import parse
from pathlib import Path
from fastapi import HTTPException
from fastapi.concurrency import run_in_threadpool
from sqlalchemy.orm import Session
from pdf2image import convert_from_path
from PIL import Image
import easyocr
from google import genai

from ..models.ocr_result_model import OCRResult
from ..models.business_model import Business
from ..services.sales_service import create_sale
from ..services.expense_service import create_expense
from ..services.profit_service import calculate_and_store_profit
from ..services.cash_flow_service import calculate_cashflow
from ..schemas.sales_schema import SaleCreate
from ..schemas.expense_schema import ExpenseCreate
from ..schemas.ocr_result_schema import OCRResponse

# ----------------------------
# Logger
# ----------------------------
logger = logging.getLogger("document_ai_service")

# ----------------------------
# Config
# ----------------------------
CONFIDENCE_THRESHOLD = 0.7
GEMINI_KEY = os.getenv("GEMINI_API_KEY")

if not GEMINI_KEY:
    raise RuntimeError("GEMINI_API_KEY is missing")

client = genai.Client(api_key=GEMINI_KEY)
MODEL_NAME = "gemini-3.6-flash"


# ----------------------------
# OCR Extraction
# ----------------------------
reader = easyocr.Reader(["en"])
async def extract_text_from_file(file_path: str) -> str:
    text = ""
    ext = Path(file_path).suffix.lower()

    try:
        if ext == ".pdf":
            pages = convert_from_path(file_path)

            for page in pages:
                results = reader.readtext(page)

                page_text = "\n".join(
                    result[1]
                    for result in results
                )

                text += page_text + "\n"

        elif ext in (".png", ".jpg", ".jpeg"):
            results = reader.readtext(file_path)

            text = "\n".join(
                result[1]
                for result in results
            )

        else:
            with open(
                    file_path,
                    "r",
                    encoding="utf-8",
                    errors="ignore"
            ) as f:
                text = f.read()

    except Exception as e:
        logger.error(f"OCR extraction failed: {e}")

        raise HTTPException(
            status_code=500,
            detail="Failed to extract text"
        )

    return text.strip()


# ----------------------------
# Main AI Processing
# ----------------------------
async def process_document_ai(
        db: Session,
        business: Business,
        document_id: int,
        file_path: str
) -> OCRResponse:

    # ----------------------------
    # Step 1: OCR
    # ----------------------------
    text_content = await extract_text_from_file(file_path)

    # ----------------------------
    # Step 2: AI Prompt (LANG-AWARE)
    # ----------------------------
    prompt = f"""
You are a financial AI assistant.

Extract structured financial data from the document.

Return ONLY valid JSON.
Do not add explanations or markdown.
Do not translate the extracted information.

TEXT:
{text_content[:5000]}

Return ONLY:

{{
  "type": "sale" | "expense",
  "amount": float,
  "party": string,
  "category": string,
  "date": "YYYY-MM-DD",
  "confidence": float,
  "raw_text": string
}}
"""

    # ----------------------------
    # Step 3: Gemini Call
    # ----------------------------
    try:
        response = await run_in_threadpool(
            lambda: client.models.generate_content(
                model=MODEL_NAME,
                contents=prompt
            )
        )

        ai_output = json.loads(response.text)

    except Exception as e:
        logger.error(f"Gemini failed: {e}")

        ai_output = {
            "type": "expense",
            "amount": 0.0,
            "party": None,
            "category": "Unknown",
            "date": str(datetime.utcnow().date()),
            "confidence": 0.5,
            "raw_text": text_content
        }

    # ----------------------------
    # Step 4: Date parsing
    # ----------------------------
    try:
        detected_date: date = parse(ai_output.get("date")).date()
    except Exception:
        detected_date = datetime.utcnow().date()

    # ----------------------------
    # Step 5: Save OCR Result (NO TRANSLATION)
    # ----------------------------
    ocr = OCRResult(
        business_id=business.id,
        document_id=document_id,
        detected_type=ai_output.get("type"),
        detected_amount=ai_output.get("amount", 0.0),
        detected_party=ai_output.get("party"),
        detected_category=ai_output.get("category"),
        detected_date=detected_date,
        raw_text=ai_output.get("raw_text", text_content),
        confidence=ai_output.get("confidence", 0.5)
    )

    db.add(ocr)
    db.commit()
    db.refresh(ocr)

    # ----------------------------
    # Step 6: Auto-create records
    # ----------------------------
    if ai_output.get("confidence", 0) >= CONFIDENCE_THRESHOLD:

        try:
            if ai_output["type"] == "sale":
                create_sale(
                    db,
                    business,
                    SaleCreate(
                        amount=ai_output["amount"],
                        customer_name=ai_output.get("party"),
                        category=ai_output.get("category"),
                        sale_date=detected_date,
                        is_paid=True
                    )
                )

            elif ai_output["type"] == "expense":

                create_expense(
                    db,
                    business,
                    ExpenseCreate(
                        amount=ai_output["amount"],
                        vendor_name=ai_output.get("party"),
                        category=ai_output.get("category"),
                        expense_date=detected_date,
                        is_paid=True
                    )
                )

            # Update financials
            calculate_and_store_profit(db, business.id)
            calculate_cashflow(db, business.id)

        except Exception as e:
            print("Error type:", type(e).__name__)


    # ----------------------------
    # Step 7: Response
    # ----------------------------
    return OCRResponse.from_orm(ocr)

