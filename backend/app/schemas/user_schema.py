from pydantic import BaseModel, EmailStr
from typing import Optional

class UserResponse(BaseModel):
    id: int
    mobile: str
    email: Optional[EmailStr] = None

    class Config:
        from_attributes = True
