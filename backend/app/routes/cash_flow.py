from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from ..models.business_model import Business
from ..schemas.cash_flow_schema import CashFlowResponse
from ..services.cash_flow_service import calculate_cashflow
from ..utils.auth_dependency import get_current_business

router = APIRouter(prefix="/cashflow", tags=["Cash Flow"])


@router.post("/calculate", response_model=CashFlowResponse)
async def calculate_full_cashflow(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """
    Calculate and store full cashflow for the current business.
    """

    try:
        return calculate_cashflow(
            db=db,
            business=business  # ✅ FIXED
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to calculate cashflow: {str(e)}"
        )