from pydantic import BaseModel
from datetime import date

class ExpenseCreate(BaseModel):
    amount: float
    vendor_name: str | None = None
    category: str | None = None
    description: str | None = None
    expense_date: date
    is_paid: bool

class ExpenseResponse(BaseModel):
    id: int
    business_id: int
    amount: float
    vendor_name: str | None = None
    category: str | None = None
    description: str | None = None
    expense_date: date
    is_paid: bool

    class Config:
        from_attributes = True
