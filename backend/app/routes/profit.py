# routes/profit_route.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from ..schemas.profit_schema import ProfitResponse
from ..models.business_model import Business
from ..services.profit_service import calculate_and_store_profit
from ..utils.auth_dependency import get_current_business

router = APIRouter(prefix="/profit", tags=["Profit"])


@router.post("/calculate", response_model=ProfitResponse)
def calculate_profit(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """
    Calculate and store profit for the current business.
    This endpoint uses the authenticated business from the current user.
    """
    try:
        # Call the service layer to calculate and store profit
        profit = calculate_and_store_profit(db, business)
        return profit

    except Exception as e:
        # Handle any unexpected errors
        raise HTTPException(
            status_code=500,
            detail=f"Failed to calculate profit: {str(e)}"
        )