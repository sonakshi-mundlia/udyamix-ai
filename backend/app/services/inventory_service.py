from sqlalchemy.orm import Session
from ..models.inventory_model import Inventory
from ..schemas.inventory_schema import InventoryCreate, InventoryResponse
from fastapi import HTTPException
from ..models.business_model import Business

# ----------------------------
# Create inventory
# ----------------------------
def create_inventory(db: Session, business: Business, data: InventoryCreate) -> InventoryResponse:
    inventory = Inventory(
        business_id=business.id,
        product_name=data.product_name,
        brand=data.brand,
        quantity=data.quantity,
        stock_quantity=data.quantity,
        price_per_unit=data.price_per_unit,
        unit=data.unit
    )
    db.add(inventory)
    db.commit()
    db.refresh(inventory)
    return InventoryResponse.from_orm(inventory)

# ----------------------------
# Get all inventory
# ----------------------------
def get_inventory(db: Session, business: Business) -> list[InventoryResponse]:
    items = db.query(Inventory).filter(Inventory.business_id == business.id).all()
    return [InventoryResponse.from_orm(item) for item in items]

# ----------------------------
# Update inventory
# ----------------------------
def update_inventory(db: Session, business: Business, inventory_id: int, data: InventoryCreate) -> InventoryResponse:
    inventory = db.query(Inventory).filter(
        Inventory.id == inventory_id,
        Inventory.business_id == business.id
    ).first()

    if not inventory:
        raise HTTPException(status_code=404, detail="Inventory item not found")

    inventory.product_name = data.product_name
    inventory.brand = data.brand
    inventory.quantity = data.quantity
    inventory.stock_quantity = data.quantity
    inventory.price_per_unit = data.price_per_unit
    inventory.unit = data.unit

    db.commit()
    db.refresh(inventory)
    return InventoryResponse.from_orm(inventory)

# ----------------------------
# Delete inventory
# ----------------------------
def delete_inventory(db: Session, business: Business, inventory_id: int) -> dict:
    inventory = db.query(Inventory).filter(
        Inventory.id == inventory_id,
        Inventory.business_id == business.id
    ).first()

    if not inventory:
        raise HTTPException(status_code=404, detail="Inventory item not found")

    db.delete(inventory)
    db.commit()
    return {"detail": "Inventory item deleted successfully"}