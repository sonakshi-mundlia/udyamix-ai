from pydantic import BaseModel
from typing import List, Dict
from datetime import datetime

class DashboardResponse(BaseModel):
    sales: float
    expenses: float
    profit: float
    loss: float
    cashFlow: float
    pendingCOD: float
    receivables: float
    salesTrend: List[float]
    expensesTrend: List[float]
    expenseCategories: Dict[str, float]
    date: datetime
    startDate: datetime

    class Config:
        from_attributes = True


class FullDashboardResponse(BaseModel):
    daily: DashboardResponse
    weekly: DashboardResponse
    monthly: DashboardResponse
    total: DashboardResponse

    class Config:
        from_attributes = True


