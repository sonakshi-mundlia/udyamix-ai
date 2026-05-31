from pydantic import BaseModel, EmailStr, field_validator, model_validator
from typing import Optional
from uuid import UUID

# -------------------
# REGISTER SCHEMA
# -------------------
class RegisterSchema(BaseModel):
    name: str
    mobile: str
    email: Optional[EmailStr] = None
    password: str
    business_name: str

    @field_validator("mobile")
    @classmethod
    def validate_mobile(cls, v):
        if not v.isdigit():
            raise ValueError("Mobile must contain only digits")
        if len(v) != 10:
            raise ValueError("Mobile must be exactly 10 digits")
        return v


# -------------------
# LOGIN SCHEMA
# -------------------
class LoginSchema(BaseModel):
    mobile: str
    email: Optional[EmailStr] = None
    password: str
    business_id: UUID

    @field_validator("mobile")
    @classmethod
    def validate_mobile(cls, v):
        if v is None:
            return v
        if not v.isdigit():
            raise ValueError("Mobile must contain only digits")
        if len(v) != 10:
            raise ValueError("Mobile must be exactly 10 digits")
        return v

    @model_validator(mode="after")
    def check_mobile_or_email(self):
        if not self.mobile and not self.email:
            raise ValueError("Either mobile or email must be provided")
        return self

class LoginBusinessRequest(BaseModel):
    mobile: str
    email: Optional[EmailStr] = None

# -------------------
# REGISTER RESPONSE
# -------------------
class RegisterResponse(BaseModel):
    message: str
    access_token: str
    token_type: str
    business_id: UUID
    business_name: str

    class Config:
        from_attributes = True


# -------------------
# LOGIN RESPONSE
# -------------------
class LoginResponse(BaseModel):
    access_token: str
    token_type: str
    business_id: UUID
    business_name: str

    class Config:
        from_attributes = True

