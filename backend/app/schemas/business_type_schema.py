from pydantic import BaseModel
from typing import List, Dict, Any, Optional

class BusinessTypeBase(BaseModel):
    type_name: str


class BusinessTypeCreate(BusinessTypeBase):
    suggested_inventory: List[Dict[str, Any]] = []


class BusinessTypeResponse(BusinessTypeBase):
    suggested_inventory: List[Dict[str, Any]] = []

    class Config:
        from_attributes = True

