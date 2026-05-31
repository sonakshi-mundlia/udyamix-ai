# app/schemas/business_schema.py
from pydantic import BaseModel
from typing import List, Optional
from app.schemas.inventory_schema import InventoryCreate

class BusinessCreate(BaseModel):
    business_name: str
    owner_id: int
    business_type_id: Optional[int] = None  # Link to a BusinessType

class BusinessResponse(BaseModel):
    id: int
    business_name: str
    owner_id: int
    business_type_id: Optional[int]
    inventories: List[InventoryCreate] = []

    class Config:
        from_attributes = True