from fastapi import Depends, HTTPException, status, Header
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from sqlalchemy.orm import Session
from database import get_db
from fastapi import Request
from ..models.user_model import User
from ..models.business_model import Business
import os
from uuid import UUID

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM")

def get_current_user(
        token: str = Depends(oauth2_scheme),
        db: Session = Depends(get_db)
) -> User:
    """
    Extract user from JWT token
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: int | None = payload.get("user_id")

        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token"
            )

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )

        return user

    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token"
        )


# -------------------
# CURRENT BUSINESS
# -------------------
def get_current_business(
        x_business_id: str = Header(..., alias="X-Business-Id"),
        user: User = Depends(get_current_user),
        db: Session = Depends(get_db),
) -> Business:

    try:
        business_id = UUID(x_business_id)
    except ValueError:
        raise HTTPException(400, "Invalid business id")

    business = db.query(Business).filter(
        Business.business_id == business_id,
        Business.owner_id == user.id
    ).first()

    if not business:
        raise HTTPException(403, "Business not allowed")

    return business
def get_current_language(request: Request) -> str:
    """
    Resolve current language for the request.

    Priority order:
    1. Query parameter → ?lang=hi
    2. HTTP Header     → Accept-Language
    3. Default         → "en"

    Returns:
        str: ISO language code (lowercase), e.g. "en", "hi", "ta"
    """

    # 1️⃣ Query parameter has highest priority
    lang = request.query_params.get("lang")
    if lang and lang.strip():
        return lang.strip().lower()

    # 2️⃣ HTTP header fallback
    accept_language = request.headers.get("Accept-Language")
    if accept_language:
        # Example: "hi,en-US;q=0.9,en;q=0.8"
        primary_lang = accept_language.split(",")[0]
        if primary_lang.strip():
            return primary_lang.strip().lower()

    # 3️⃣ Final fallback
    return "en"
