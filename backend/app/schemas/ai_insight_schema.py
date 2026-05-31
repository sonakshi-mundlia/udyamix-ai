from pydantic import BaseModel
from typing import Optional, List, Literal

# -------------------- Extra Data --------------------
class AIInsightExtraData(BaseModel):
    urgency: Literal["high", "medium", "low"]
    root_cause: str
    impact_value: float
    formula: Optional[str] = ""
    action_plan: List[str] = []

# -------------------- AI Insight Response --------------------
class AIInsightResponse(BaseModel):
    id: Optional[int] = None
    business_id: int
    title: str
    detail: str
    score: float
    language: str
    extra_data: AIInsightExtraData
    expanded_detail: Optional[str] = None

    class Config:
        from_attributes = True

