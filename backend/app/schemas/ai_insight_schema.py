from typing import List, Optional

from pydantic import BaseModel, Field


# =========================================================
# Metric
# =========================================================

class MetricData(BaseModel):
    name: str

    current_value: float = 0

    previous_value: Optional[float] = None

    change_value: Optional[float] = None

    change_percentage: Optional[float] = None

    trend: str = "stable"


# =========================================================
# Urgency
# =========================================================

class UrgencyData(BaseModel):
    level: str = "low"

    reason: str = ""


# =========================================================
# Root Cause
# =========================================================

class RootCauseData(BaseModel):
    primary: str = ""

    possible_causes: List[str] = Field(
        default_factory=list
    )

    evidence: List[str] = Field(
        default_factory=list
    )

    confidence: float = 0


# =========================================================
# Business Impact
# =========================================================

class ImpactData(BaseModel):
    financial_value: Optional[float] = None

    estimated_revenue_loss: Optional[float] = None

    financial_impact_available: bool = False

    financial_impact_reason: str = ""

    customer_impact: str = ""

    business_risk: str = "low"


# =========================================================
# Formula
# =========================================================

class FormulaData(BaseModel):
    name: str = ""

    expression: str = ""

    calculation: str = ""

    result: str = ""


# =========================================================
# Period Comparison
# =========================================================

class ComparisonData(BaseModel):
    previous_period: Optional[float] = None

    current_period: float = 0

    difference: Optional[float] = None

    percentage_change: Optional[float] = None


# =========================================================
# Recommendations
# =========================================================

class RecommendationData(BaseModel):
    priority: str = "medium"

    immediate_actions: List[str] = Field(
        default_factory=list
    )

    short_term_actions: List[str] = Field(
        default_factory=list
    )

    long_term_actions: List[str] = Field(
        default_factory=list
    )


# =========================================================
# Action Plan
# =========================================================

class ActionItem(BaseModel):
    step: int

    action: str

    priority: str = "medium"


# =========================================================
# Complete AI Insight Extra Data
# =========================================================

class AIInsightExtraData(BaseModel):

    metric: MetricData

    urgency: UrgencyData

    root_cause: RootCauseData

    impact: ImpactData

    formula: FormulaData

    comparison: ComparisonData

    recommendation: RecommendationData

    action_plan: List[ActionItem] = Field(
        default_factory=list
    )

    expected_outcome: str = ""

    monitor: List[str] = Field(
        default_factory=list
    )


# =========================================================
# AI Insight Response
# =========================================================

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

