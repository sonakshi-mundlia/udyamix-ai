from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from ..models.business_model import Business
from ..services.business_service import update_business_name, delete_business_and_owner
from ..utils.auth_dependency import get_current_business  # your dependencies

router = APIRouter(
    prefix="/business",
    tags=["Business"]
)

# ------------------------------
# Update business name
# ------------------------------
@router.put("/update-name")
def put_business_name(data: dict,
                      db: Session = Depends(get_db),
                      current_business: Business = Depends(get_current_business)):
    """
    Update the name of the current business.
    Expects JSON body: { "name": "New Business Name" }
    """
    new_name = data.get("name")
    if not new_name:
        raise HTTPException(status_code=400, detail="New name is required")

    updated_business = update_business_name(db, current_business, new_name)

    return {
        "success": True,
        "business": {
            "id": updated_business.id,
            "name": updated_business.business_name,
            "owner_id": updated_business.owner_id
        }
    }


# ------------------------------
# Delete current business
# ------------------------------
@router.delete("/delete")
def delete_business(db: Session = Depends(get_db),
                    current_business: Business = Depends(get_current_business)):
    """
    Delete the current business.
    Deletes the owner user only if they have no other businesses.
    """
    result = delete_business_and_owner(db, current_business)
    return result

