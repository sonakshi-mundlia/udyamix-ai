from pydantic import BaseModel
from typing import Optional

class ProfitResponse(BaseModel):
    total_sales: float
    total_expenses: float
    profit_amount: Optional[float]
    loss_amount: Optional[float]
    status: str

    class Config:
        from_attributes = True
