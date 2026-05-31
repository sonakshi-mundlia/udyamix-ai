from pydantic import BaseModel
from datetime import datetime

class DocumentResponse(BaseModel):
    id: int
    file_path: str
    file_type: str
    created_at: datetime

    class Config:
        from_attributes = True
