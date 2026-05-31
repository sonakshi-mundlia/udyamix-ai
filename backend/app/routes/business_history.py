from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session

from ..models.business_model import Business
from ..services.business_history_service import get_historical_summary
from ..utils.auth_dependency import get_current_business, get_current_language
from database import get_db

router = APIRouter(
    prefix="/history",
    tags=["Business History"]
)


@router.get("/")
async def business_history(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business),
        period: str = Query("weekly", description="Period: daily / weekly / monthly"),
        lang: str = Depends(get_current_language)
):
    """
    Fetch historical summary for the current business.
    """

    # ----------------------------
    # Validate period
    # ----------------------------
    if period not in ["daily", "weekly", "monthly"]:
        raise HTTPException(
            status_code=400,
            detail="Invalid period. Use daily, weekly, or monthly."
        )

    try:
        # ----------------------------
        # Call service (FIXED)
        # ----------------------------
        result = await get_historical_summary(
            db=db,
            business=business,
            period=period,
            lang=lang
        )

        return {
            "success": True,
            "business_id": str(business.business_id),
            "period": period,
            **result  # includes raw_summary + ai_summary + language
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch business history: {str(e)}"
        )

