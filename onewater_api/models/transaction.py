from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime
from enum import Enum


class PaymentStatus(str, Enum):
    paid = "paid"
    pending = "pending"
    partial = "partial"
    voided = "voided"


class PaymentMethod(str, Enum):
    cash = "cash"
    bank_transfer = "bank_transfer"
    easypaisa = "easypaisa"
    jazzcash = "jazzcash"
    credit = "credit"


class TransactionItemCreate(BaseModel):
    product_id: str
    product_name: str
    quantity: int
    unit_price: float
    line_total: float


class TransactionCreate(BaseModel):
    customer_id: str
    customer_name: str
    customer_phone: Optional[str] = None
    transaction_date: date = None
    due_date: Optional[date] = None
    items: List[TransactionItemCreate]
    subtotal: float
    discount: float = 0
    total_amount: float
    amount_paid: float = 0
    payment_status: PaymentStatus = PaymentStatus.paid
    payment_method: Optional[PaymentMethod] = PaymentMethod.cash
    notes: Optional[str] = None


class TransactionUpdate(BaseModel):
    due_date: Optional[date] = None
    discount: Optional[float] = None
    total_amount: Optional[float] = None
    amount_paid: Optional[float] = None
    payment_status: Optional[PaymentStatus] = None
    payment_method: Optional[PaymentMethod] = None
    notes: Optional[str] = None


class TransactionItemResponse(BaseModel):
    id: str
    transaction_id: str
    product_id: str
    product_name: str
    quantity: int
    unit_price: float
    line_total: float


class TransactionResponse(BaseModel):
    id: str
    invoice_number: str
    customer_id: str
    customer_name: str
    customer_phone: Optional[str] = None
    created_by: Optional[str] = None
    transaction_date: date
    due_date: Optional[date] = None
    subtotal: float
    discount: float
    total_amount: float
    amount_paid: float
    payment_status: str
    payment_method: Optional[str] = None
    notes: Optional[str] = None
    invoice_pdf_url: Optional[str] = None
    items: List[TransactionItemResponse] = []
    created_at: datetime

    class Config:
        from_attributes = True


class CollectPaymentRequest(BaseModel):
    amount: float
    payment_method: PaymentMethod
    notes: Optional[str] = None


class PaymentCollectionResponse(BaseModel):
    id: str
    transaction_id: str
    collected_by: Optional[str] = None
    amount: float
    collected_at: datetime
    payment_method: str
    notes: Optional[str] = None

    class Config:
        from_attributes = True
