from pydantic import BaseModel
from datetime import datetime

class OCRResponse(BaseModel):
    id: int
    document_id: int
    detected_type: str
    detected_amount: float | None
    detected_party: str | None
    detected_category: str | None
    detected_date: str | None
    confidence: float
    created_at: datetime

    class Config:
        from_attributes = True
