from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from typing import Optional
from ..models.business_model import Business
from ..services.ai_service import analyze_business
from ..utils.auth_dependency import get_current_business, get_current_language
from database import get_db
from ..schemas.dashboard_background_schema import DashboardBackgroundResponse

router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard-background"]
)


@router.get("/background", response_model=DashboardBackgroundResponse)
async def get_dashboard_background(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business),
        desired_count: Optional[int] = 12,
        lang: str = Depends(get_current_language)
):
    """
    Fetch the dashboard background and suggested inventory for the current business.
    Handles empty suggested items if AI service fails or user has inventory.
    """
    try:
        response = await analyze_business(
            db=db,
            business=business,
            desired_count=desired_count,
            lang=lang,
        )
        return response
    except Exception as e:
        # If AI fails completely, return empty suggestions but theme still available
        return DashboardBackgroundResponse(
            success=False,
            data=[],
            ai_error=True
        )
