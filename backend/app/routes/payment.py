# routes/payment_route.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from ..models.business_model import Business
from ..schemas.payment_schema import PaymentCreate, PaymentResponse
from ..services.payment_service import create_payment, get_payments
from ..utils.auth_dependency import get_current_business

router = APIRouter(prefix="/payments", tags=["Payments"])


# ------------------------
# CREATE PAYMENT
# ------------------------
@router.post("/", response_model=PaymentResponse)
def add_payment(
        data: PaymentCreate,
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """
    Create a new payment record for the current business.
    """
    try:
        payment = create_payment(
            db=db,
            business=business,
            amount=data.amount,
            payment_mode=data.payment_mode,
            payment_date=data.payment_date
        )
        return payment

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create payment: {str(e)}"
        )


# ------------------------
# LIST PAYMENTS
# ------------------------
@router.get("/record", response_model=List[PaymentResponse])
def list_payments(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """
    List all payments for the current business.
    """
    try:
        payments = get_payments(db, business)
        return payments

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch payments: {str(e)}"
        )