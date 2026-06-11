from pydantic import BaseModel, EmailStr
from uuid import UUID
from datetime import datetime
from typing import Optional, Dict, Any


class UserRegister(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    phone: Optional[str] = None
    nationality: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    nationality: Optional[str] = None
    date_of_birth: Optional[str] = None
    passport_number: Optional[str] = None
    passport_expiry: Optional[str] = None
    education_level: Optional[str] = None
    work_years: Optional[int] = None
    language_scores: Optional[Dict[str, Any]] = None
    financial_info: Optional[Dict[str, Any]] = None
    travel_history: Optional[Any] = None
    fcm_token: Optional[str] = None


class UserOut(BaseModel):
    id: UUID
    email: str
    full_name: str
    phone: Optional[str]
    nationality: Optional[str]
    passport_expiry: Optional[str]
    education_level: Optional[str]
    subscription_tier: str
    is_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserOut
