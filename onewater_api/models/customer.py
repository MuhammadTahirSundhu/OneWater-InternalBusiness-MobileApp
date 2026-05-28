from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class CustomerCreate(BaseModel):
    name: str
    phone: Optional[str] = None
    address: Optional[str] = None
    area: Optional[str] = None
    notes: Optional[str] = None


class CustomerUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    area: Optional[str] = None
    notes: Optional[str] = None


class CustomerResponse(BaseModel):
    id: str
    name: str
    phone: Optional[str] = None
    address: Optional[str] = None
    area: Optional[str] = None
    notes: Optional[str] = None
    total_pending: float = 0
    created_by: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
