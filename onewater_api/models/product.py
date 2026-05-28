from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum


class ProductCategory(str, Enum):
    bottle_pack_500ml = "bottle_pack_500ml"
    bottle_1_5L = "bottle_1_5L"
    bottle_19L_new = "bottle_19L_new"
    bottle_19L_refill = "bottle_19L_refill"


class ProductCreate(BaseModel):
    name: str
    sku: str
    category: ProductCategory
    unit_price: float
    security_deposit: float = 0


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    sku: Optional[str] = None
    category: Optional[ProductCategory] = None
    unit_price: Optional[float] = None
    security_deposit: Optional[float] = None
    is_active: Optional[bool] = None


class ProductResponse(BaseModel):
    id: str
    name: str
    sku: str
    category: str
    unit_price: float
    security_deposit: float
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True
