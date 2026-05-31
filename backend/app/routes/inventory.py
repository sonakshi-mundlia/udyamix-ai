# app/routes/inventory_route.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from ..schemas.inventory_schema import InventoryCreate, InventoryResponse
from ..models.business_model import Business
from database import get_db
from ..utils.auth_dependency import get_current_business
from ..services.inventory_service import (
    create_inventory,
    get_inventory,
    update_inventory,
    delete_inventory
)

router = APIRouter(prefix="/inventory", tags=["Inventory"])


@router.post("/", response_model=InventoryResponse)
def add_inventory(
        data: InventoryCreate,
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """
    Add a new product to the current business inventory
    """
    return create_inventory(db, business, data)


@router.get("/list", response_model=List[InventoryResponse])
def list_inventory(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """
    List all inventory items for the current business
    """
    return get_inventory(db, business)


@router.put("/{inventory_id}", response_model=InventoryResponse)
def edit_inventory(
        inventory_id: int,  # Change to UUID if your table uses UUIDs
        data: InventoryCreate,
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """
    Update an existing inventory item for the current business
    """
    # Service will raise 404 if inventory not found
    return update_inventory(db, business, inventory_id, data)


@router.delete("/{inventory_id}")
def remove_inventory(
        inventory_id: int,  # Change to UUID if your table uses UUIDs
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """
    Delete an inventory item belonging to the current business
    """
    # Service will raise 404 if inventory not found
    return delete_inventory(db, business, inventory_id)
