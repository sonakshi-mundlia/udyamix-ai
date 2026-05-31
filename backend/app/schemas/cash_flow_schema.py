from pydantic import BaseModel

class CashFlowResponse(BaseModel):
    cash_in: float
    cash_out: float
    net_cashflow: float
    status: str

    class Config:
        from_attributes = True
