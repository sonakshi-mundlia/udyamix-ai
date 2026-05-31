# backend/app/api/ai_insights.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from ..models.business_model import Business
from ..schemas.ai_insight_schema import AIInsightResponse
from ..services.ai_insight_service import fetch_ai_insights
from ..utils.auth_dependency import get_current_business, get_current_language

router = APIRouter(prefix="/ai-insights", tags=["AI Insights"])

@router.get("/", response_model=List[AIInsightResponse])
async def get_ai_insights(
        window: int = Query(7, description="Window in days (7 or 30)"),
        business: Business = Depends(get_current_business),
        lang: str = Depends(get_current_language),
        db: Session = Depends(get_db)
):
    """
    Fetch AI insights for a business.
    - window: 7 or 30 days
    - lang: language code (en, hi, ta, etc.)
    """
    # Validate window
    if window not in [7, 30]:
        raise HTTPException(status_code=400, detail="Window must be 7 or 30 days")

    if not business:
        raise HTTPException(status_code=404, detail="Business not found")

    # Fetch AI insights
    insights = await fetch_ai_insights(db, business, lang, window)
    return insights
