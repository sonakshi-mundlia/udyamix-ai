from sqlalchemy.orm import Session
from fastapi import HTTPException
from ..models.business_model import Business
from ..models.user_model import User

# ------------------------------
# UPDATE BUSINESS NAME
# ------------------------------
def update_business_name(db: Session, business: Business, new_name: str):
    """
    Update only the business name using Business.id
    """
    if not business:
        raise HTTPException(status_code=404, detail="Business not found")

    business.business_name = new_name
    db.commit()
    db.refresh(business)
    return business

# ------------------------------
# DELETE BUSINESS & OWNER
# ------------------------------
def delete_business_and_owner(db: Session, business: Business):
    """
    Delete a business using Business.id.
    Delete the owner user ONLY if they have no other businesses.
    """
    if not business:
        raise HTTPException(status_code=404, detail="Business not found")

    owner = None
    if business.owner_id:
        owner = db.query(User).filter(User.id == business.owner_id).first()

    # Delete the business first
    db.delete(business)
    db.commit()  # commit deletion of business

    # Safety check: delete owner ONLY if they have no other businesses
    if owner:
        other_businesses = db.query(Business).filter(
            Business.owner_id == owner.id
        ).count()
        if other_businesses == 0:
            db.delete(owner)
            db.commit()
            return {
                "success": True,
                "message": "Business deleted and owner account deleted (no other businesses).",
                "business": business  # return the deleted business object
            }

    return {
        "success": True,
        "message": "Business deleted. Owner account retained (owns other businesses).",
        "business": business  # return the deleted business object
    }
