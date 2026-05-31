from pydantic import BaseModel
from typing import Optional
from datetime import datetime

# ------------------- Create / Input Model -------------------
class InventoryCreate(BaseModel):
    product_name: str
    brand: Optional[str] = None
    quantity: float
    unit: str
    stock_quantity: int
    price_per_unit: float

# ------------------- Response / Output Model -------------------
class InventoryResponse(BaseModel):
    id: int
    business_id: int
    product_name: str
    brand: Optional[str] = None
    quantity: float
    unit: str
    stock_quantity: int
    price_per_unit: float
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True