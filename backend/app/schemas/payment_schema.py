from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional

class PaymentCreate(BaseModel):
    amount: float
    payment_mode: str
    payment_date: date
    sale_id: Optional[int] = None
    expense_id: Optional[int] = None
    direction: Optional[str] = "in"


class PaymentResponse(BaseModel):
    id: int
    business_id: int
    sale_id: Optional[int] = None
    expense_id: Optional[int] = None
    amount: float
    payment_id: str
    order_id: Optional[str] = None
    payment_mode: str
    status: str
    direction: str
    payment_date: date
    created_at: datetime

    class Config:
        from_attributes = True
