from pydantic import BaseModel
from typing import List, Optional

# Suggested product
class SuggestedProduct(BaseModel):
    product_name: str
    brand: Optional[str] = None


# Final API response (ONLY suggestions)
class DashboardBackgroundResponse(BaseModel):
    success: bool
    data: List[SuggestedProduct]
    ai_error: bool = False

