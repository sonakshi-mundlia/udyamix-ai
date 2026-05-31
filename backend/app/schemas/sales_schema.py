from pydantic import BaseModel
from datetime import date

class SaleCreate(BaseModel):
    amount: float
    customer_name: str | None
    category: str | None
    description: str | None
    sale_date: date
    is_paid: bool


class SaleResponse(BaseModel):
    id: int
    business_id: int
    amount: float
    customer_name: str | None
    category: str | None
    description: str | None
    sale_date: date
    is_paid: bool

    class Config:
        from_attributes = True

