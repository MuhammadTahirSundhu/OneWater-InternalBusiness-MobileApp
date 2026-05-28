from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
from enum import Enum


class UserRole(str, Enum):
    admin = "admin"
    manager = "manager"
    salesman = "salesman"


class UserCreate(BaseModel):
    full_name: str
    phone: str
    email: Optional[str] = None
    role: UserRole
    password: str


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None
    avatar_url: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    full_name: str
    phone: str
    email: Optional[str] = None
    role: str
    is_active: bool
    avatar_url: Optional[str] = None
    onboarding_done: bool
    created_at: datetime

    class Config:
        from_attributes = True


class LoginRequest(BaseModel):
    identifier: str   # phone or email
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


class UpdateProfileRequest(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    avatar_url: Optional[str] = None
    onboarding_done: Optional[bool] = None
