from enum import Enum

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from ..models.business_model import Business
from ..schemas.ai_insight_schema import AIInsightResponse
from ..services.ai_insight_service import fetch_ai_insights
from ..utils.auth_dependency import get_current_business, get_current_language


router = APIRouter(prefix="/ai-insights", tags=["AI Insights"])


class InsightWindow(str, Enum):
    DAYS_7 = "7"
    DAYS_30 = "30"
    ALL = "all"


@router.get("/", response_model=List[AIInsightResponse])
async def get_ai_insights(
        window: InsightWindow = Query(
            InsightWindow.DAYS_7,
            description="Window in days: 7, 30, or all",
        ),
        business: Business = Depends(get_current_business),
        lang: str = Depends(get_current_language),
        db: Session = Depends(get_db),
):
    if not business:
        raise HTTPException(
            status_code=404,
            detail="Business not found",
        )

    if window == InsightWindow.DAYS_7:
        window_value = 7

    elif window == InsightWindow.DAYS_30:
        window_value = 30

    else:
        window_value = "all"

    insights = await fetch_ai_insights(
        db,
        business,
        lang,
        window_value,
    )

    return insights