from pydantic import BaseModel
from typing import Optional
from datetime import datetime, date
from enum import Enum


class ExpenseCategory(str, Enum):
    fuel = "fuel"
    salary = "salary"
    utilities = "utilities"
    office = "office"
    maintenance = "maintenance"
    other = "other"


class ExpenseCreate(BaseModel):
    description: str
    amount: float
    category: ExpenseCategory = ExpenseCategory.other
    expense_date: Optional[date] = None
    notes: Optional[str] = None


class ExpenseResponse(BaseModel):
    id: str
    description: str
    amount: float
    category: str
    expense_date: date
    notes: Optional[str] = None
    recorded_by: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class AmountInCreate(BaseModel):
    description: str
    amount: float
    notes: Optional[str] = None
    recorded_date: Optional[date] = None


class AmountInResponse(BaseModel):
    id: str
    description: str
    amount: float
    notes: Optional[str] = None
    recorded_by: Optional[str] = None
    recorded_date: date
    created_at: datetime

    class Config:
        from_attributes = True
