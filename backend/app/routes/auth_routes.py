# app/routes/auth_routes.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import os
from typing import List

from ..schemas.auth_schema import (
    RegisterSchema, LoginSchema, RegisterResponse, LoginResponse, LoginBusinessRequest
)
from ..services.auth_service import register_user, authenticate_user, force_logout, update_user_info, update_user_password
from database import get_db
from ..utils.jwt import create_access_token
from ..utils.auth_dependency import get_current_user
from ..models.user_model import User
from ..models.business_model import Business

router = APIRouter(prefix="/auth", tags=["Auth"])

ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 60))


# ------------------------
# REGISTER
# ------------------------
@router.post("/register", response_model=RegisterResponse)
def register(data: RegisterSchema, db: Session = Depends(get_db)):
    try:
        user, business = register_user(db, data)

        # ✅ FIX: use UUID business_id (safe)
        token = create_access_token(
            data={
                "user_id": user.id,  # keep int internally
                "business_id": str(business.business_id),  # ✅ FIXED
                "token_version": user.token_version
            },
            expires_minutes=ACCESS_TOKEN_EXPIRE_MINUTES
        )

        return {
            "message": "Registered successfully",
            "access_token": token,
            "token_type": "bearer",
            "business_id": str(business.business_id),
            "business_name": business.business_name
        }

    except HTTPException as e:
        raise e
    except Exception as e:
        print("Registration error:", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Something went wrong during registration"
        )


# ------------------------
# LOGIN
# ------------------------
@router.post("/login", response_model=LoginResponse)
def login(data: LoginSchema, db: Session = Depends(get_db)):
    result = authenticate_user(db, data)
    if not result:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    user, business = result

    # ✅ FIX: use UUID business_id
    token = create_access_token(
        data={
            "user_id": user.id,
            "business_id": str(business.business_id),  # ✅ FIXED
            "token_version": user.token_version
        },
        expires_minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )

    return {
        "access_token": token,
        "token_type": "bearer",
        "business_id": str(business.business_id),
        "business_name": business.business_name
    }


# ------------------------
# FETCH BUSINESSES (LOGIN)
# ------------------------
@router.post("/login/businesses")
def get_login_businesses(
        data: LoginBusinessRequest,
        db: Session = Depends(get_db)
):
    user = None

    if data.email:
        user = db.query(User).filter(User.email == data.email).first()
    elif data.mobile:
        user = db.query(User).filter(User.mobile == data.mobile).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    businesses = db.query(Business).filter(Business.owner_id == user.id).all()

    selected_business = businesses[0] if len(businesses) == 1 else None

    return {
        "user_id": user.id,
        "businesses": [
            {
                "business_id": str(b.business_id),
                "business_name": b.business_name
            }
            for b in businesses
        ],
        "selected_business_id": str(selected_business.business_id) if selected_business else None
    }


# ------------------------
# MY BUSINESSES
# ------------------------
@router.get("/my-businesses", response_model=List[dict])
def get_user_businesses(
        user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
):
    businesses = db.query(Business).filter(Business.owner_id == user.id).all()

    return [
        {
            "business_id": str(b.business_id),
            "business_name": b.business_name
        }
        for b in businesses
    ]

@router.get("/profile")
def get_profile(user: User = Depends(get_current_user)):
    """
    Returns the logged-in user's info: name, email, mobile, etc.
    Requires Authorization header with Bearer token.
    """
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "mobile": user.mobile
    }

# ------------------------
# LOGOUT
# ------------------------
@router.post("/logout")
def logout(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    force_logout(db, user)
    return {"message": "Logged out successfully"}


# Update user info (name, email, mobile)
@router.put("/update-info")
def put_user_info(data: dict, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Update logged-in user's profile info securely.
    """
    user = update_user_info(
        db,
        current_user.id,
        name=data.get("name"),
        email=data.get("email"),
        mobile=data.get("mobile")
    )
    return {
        "success": True,
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "mobile": user.mobile
        }
    }


# Change password
@router.patch("/update-password")
def patch_user_password(data: dict, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Change logged-in user's password securely.
    """
    user = update_user_password(
        db,
        current_user.id,
        old_password=data["old_password"],
        new_password=data["new_password"]
    )
    return {"success": True, "message": "Password updated successfully"}

