# app/services/payment_service.py

from sqlalchemy.orm import Session
from datetime import date
from uuid import uuid4
from typing import Optional, List

from ..models.payment_model import Payment
from ..schemas.payment_schema import PaymentResponse
from ..models.business_model import Business

# ----------------------------
# Create Payment
# ----------------------------
def create_payment(
        db: Session,
        business: Business,
        amount: float,
        payment_mode: str,
        payment_date: date,
        sale_id: Optional[int] = None,
        expense_id: Optional[int] = None,
        direction: str = "in",
        status: str = "completed"
) -> PaymentResponse:
    """
    Creates a payment record for a business, linked to Sale or Expense if provided.
    Returns a PaymentResponse (Pydantic schema) for consistency.
    """

    payment = Payment(
        business_id=business.id,
        sale_id=sale_id,
        expense_id=expense_id,
        amount=amount,
        payment_mode=payment_mode,
        payment_id=uuid4(),  # UUID for unique payment reference
        order_id=uuid4() if sale_id else None,
        status=status,
        direction=direction,
        payment_date=payment_date
    )

    db.add(payment)
    db.commit()
    db.refresh(payment)

    # Return Pydantic response
    return PaymentResponse.from_orm(payment)


# ----------------------------
# Get all payments
# ----------------------------
def get_payments(db: Session, business: Business) -> List[PaymentResponse]:
    """
    Returns all payments for a given business as Pydantic responses.
    """
    payments = db.query(Payment).filter(Payment.business_id == business.id).all()
    return [PaymentResponse.from_orm(p) for p in payments]


# ----------------------------
# Get payments by direction
# ----------------------------
def get_payments_by_direction(
        db: Session,
        business: Business,
        direction: str = "in"
) -> List[PaymentResponse]:
    """
    Returns payments filtered by 'in' (income) or 'out' (expense).
    """
    payments = (
        db.query(Payment)
        .filter(Payment.business_id == business.id, Payment.direction == direction)
        .all()
    )
    return [PaymentResponse.from_orm(p) for p in payments]

