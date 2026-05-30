from fastapi import APIRouter, Depends, HTTPException, Query, status
from datetime import datetime, date, timezone
from typing import Optional
from dependencies import get_supabase, get_current_user, require_admin_or_manager, require_admin
from models.expense import (
    ExpenseCreate, ExpenseResponse,
    AmountInCreate, AmountInResponse,
)
from utils.audit_writer import write_audit

router = APIRouter()


# ─────────────────────────────────────────
# EXPENSES
# ─────────────────────────────────────────

@router.get("/", response_model=list[ExpenseResponse])
async def list_expenses(
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    category: Optional[str] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(require_admin_or_manager),
):
    db = get_supabase()
    query = db.table("expenses").select("*").order("expense_date", desc=True)

    if date_from:
        query = query.gte("expense_date", date_from.isoformat())
    if date_to:
        query = query.lte("expense_date", date_to.isoformat())
    if category:
        query = query.eq("category", category)

    result = query.range(offset, offset + limit - 1).execute()
    return [ExpenseResponse(**e) for e in result.data]


@router.post("/", response_model=ExpenseResponse, status_code=status.HTTP_201_CREATED)
async def create_expense(body: ExpenseCreate, current_user: dict = Depends(get_current_user)):
    db = get_supabase()

    expense_data = {
        "description": body.description,
        "amount": float(body.amount),
        "category": body.category.value,
        "expense_date": (body.expense_date or date.today()).isoformat(),
        "notes": body.notes,
        "recorded_by": current_user["id"],
    }

    result = db.table("expenses").insert(expense_data).execute()
    new_expense = result.data[0]

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="CREATE_EXPENSE",
        entity_type="expense",
        entity_id=new_expense["id"],
        new_value=expense_data,
    )

    return ExpenseResponse(**new_expense)


@router.delete("/{expense_id}")
async def delete_expense(expense_id: str, current_user: dict = Depends(require_admin)):
    db = get_supabase()

    result = db.table("expenses").select("id").eq("id", expense_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Expense not found")

    db.table("expenses").delete().eq("id", expense_id).execute()

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="DELETE_EXPENSE",
        entity_type="expense",
        entity_id=expense_id,
    )

    return {"message": "Expense deleted"}


# ─────────────────────────────────────────
# AMOUNT IN
# ─────────────────────────────────────────

@router.get("/amount-in/", response_model=list[AmountInResponse])
async def list_amount_in(
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(require_admin_or_manager),
):
    db = get_supabase()
    query = db.table("amount_in").select("*").order("recorded_date", desc=True)

    if date_from:
        query = query.gte("recorded_date", date_from.isoformat())
    if date_to:
        query = query.lte("recorded_date", date_to.isoformat())

    result = query.range(offset, offset + limit - 1).execute()
    return [AmountInResponse(**a) for a in result.data]


@router.post("/amount-in/", response_model=AmountInResponse, status_code=status.HTTP_201_CREATED)
async def create_amount_in(body: AmountInCreate, current_user: dict = Depends(get_current_user)):
    db = get_supabase()

    data = {
        "description": body.description,
        "amount": float(body.amount),
        "notes": body.notes,
        "recorded_date": (body.recorded_date or date.today()).isoformat(),
        "recorded_by": current_user["id"],
    }

    result = db.table("amount_in").insert(data).execute()
    new_record = result.data[0]

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="CREATE_AMOUNT_IN",
        entity_type="amount_in",
        entity_id=new_record["id"],
        new_value=data,
    )

    return AmountInResponse(**new_record)


@router.delete("/amount-in/{record_id}")
async def delete_amount_in(record_id: str, current_user: dict = Depends(require_admin)):
    db = get_supabase()

    result = db.table("amount_in").select("id").eq("id", record_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Record not found")

    db.table("amount_in").delete().eq("id", record_id).execute()
    return {"message": "Amount In record deleted"}
