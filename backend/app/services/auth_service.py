# app/services/auth_service.py

from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy import or_

from ..models.user_model import User
from ..models.business_model import Business
from ..schemas.auth_schema import RegisterSchema, LoginSchema
from ..utils.password import hash_password, verify_password

# ---------------------------------------------------------
# REGISTER USER
# ---------------------------------------------------------
def register_user(db: Session, data: RegisterSchema):
    """
    Register a new user and business in one transaction.
    The business is created first; owner_id is temporarily NULL.
    """
    # 1️⃣ Check if user already exists
    existing_user = db.query(User).filter(
        or_(User.email == data.email, User.mobile == data.mobile)
    ).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile or email already exists"
        )

    try:
        # 2️⃣ Create the business first with owner_id=None
        business = Business(
            business_name=data.business_name,
            owner_id=None  # temporarily NULL
        )
        db.add(business)
        db.flush()  # assigns business.business_id (UUID)

        # 3️⃣ Create the user (no selected_business_id)
        user = User(
            name=data.name,
            email=data.email,
            mobile=data.mobile,
            password=hash_password(data.password)
        )
        db.add(user)
        db.flush()  # assigns user.id

        # 4️⃣ Update the business owner_id now that user.id exists
        business.owner_id = user.id

        # 5️⃣ Commit both in one transaction
        db.commit()
        db.refresh(user)
        db.refresh(business)

    except IntegrityError as e:
        db.rollback()
        print("IntegrityError during registration:", e)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile or email already exists"
        )
    except Exception as e:
        db.rollback()
        print("Unexpected error during registration:", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to register user: {e}"
        )

    return user, business

# ---------------------------------------------------------
# AUTHENTICATE USER
# ---------------------------------------------------------

def authenticate_user(db: Session, data: LoginSchema):
    if data.email:
        user = db.query(User).filter(User.email == data.email).first()
    else:
        user = db.query(User).filter(User.mobile == data.mobile).first()

    if not user or not verify_password(data.password, user.password):
        return None

    business = db.query(Business).filter(
        Business.business_id == data.business_id,
        Business.owner_id == user.id
    ).first()

    if not business:
        raise HTTPException(
            status_code=400,
            detail="Selected business does not belong to user"
        )

    return user, business
# ---------------------------------------------------------
# FORCE LOGOUT
# ---------------------------------------------------------
def force_logout(db: Session, user: User):
    """
    Increment token_version -> invalidate all current JWTs.
    """
    user.token_version += 1
    db.commit()


def update_user_info(db: Session, user_id: int, name: str = None, email: str = None, mobile: str = None):
    """
    Update a user's profile information: name, email, mobile.
    Checks for duplicate email/mobile.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check for duplicates
    if email and email != user.email:
        existing_email = db.query(User).filter(User.email == email).first()
        if existing_email:
            raise HTTPException(status_code=400, detail="Email already exists")
        user.email = email

    if mobile and mobile != user.mobile:
        existing_mobile = db.query(User).filter(User.mobile == mobile).first()
        if existing_mobile:
            raise HTTPException(status_code=400, detail="Mobile already exists")
        user.mobile = mobile

    if name:
        user.name = name

    db.commit()
    db.refresh(user)
    return user

def update_user_password(db: Session, user_id: int, old_password: str, new_password: str):
    """
    Update user password after verifying the old password.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if not verify_password(old_password, user.password):
        raise HTTPException(status_code=400, detail="Old password is incorrect")

    user.password = hash_password(new_password)
    db.commit()
    db.refresh(user)
    return user