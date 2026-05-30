from fastapi import APIRouter, Depends, HTTPException, Query, status
from datetime import datetime, date, timezone
from typing import Optional
from dependencies import get_supabase, get_current_user, require_admin, require_admin_or_manager
from models.transaction import (
    TransactionCreate, TransactionUpdate, TransactionResponse,
    TransactionItemResponse, CollectPaymentRequest, PaymentCollectionResponse,
)
from utils.audit_writer import write_audit
from utils.invoice_number import generate_invoice_number
from services.invoice_service import generate_invoice_pdf

router = APIRouter()


@router.get("/", response_model=list[TransactionResponse])
async def list_transactions(
    payment_status: Optional[str] = Query(None),
    customer_id: Optional[str] = Query(None),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    search: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user),
):
    db = get_supabase()
    query = db.table("transactions").select("*, users!transactions_created_by_fkey(full_name)").order("transaction_date", desc=True)

    # Salesman can only see their own transactions
    if current_user["role"] == "salesman":
        query = query.eq("created_by", current_user["id"])

    if payment_status:
        query = query.eq("payment_status", payment_status)
    if customer_id:
        query = query.eq("customer_id", customer_id)
    if date_from:
        query = query.gte("transaction_date", date_from.isoformat())
    if date_to:
        query = query.lte("transaction_date", date_to.isoformat())
    if search:
        query = query.or_(f"customer_name.ilike.%{search}%,invoice_number.ilike.%{search}%")

    result = query.range(offset, offset + limit - 1).execute()

    if not result.data:
        return []

    transaction_ids = [t["id"] for t in result.data]
    items_result = db.table("transaction_items").select("*").in_("transaction_id", transaction_ids).execute()
    
    items_by_txn = {}
    for item in items_result.data:
        txn_id = item["transaction_id"]
        if txn_id not in items_by_txn:
            items_by_txn[txn_id] = []
        items_by_txn[txn_id].append(TransactionItemResponse(**item))

    transactions = []
    for t in result.data:
        items = items_by_txn.get(t["id"], [])
        
        # Extract created_by_name
        user_data = t.pop("users", None)
        created_by_name = user_data.get("full_name") if user_data else None
        
        t_response = TransactionResponse(**t, created_by_name=created_by_name, items=items)
        transactions.append(t_response)

    return transactions


@router.post("/", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
async def create_transaction(body: TransactionCreate, current_user: dict = Depends(get_current_user)):
    db = get_supabase()

    invoice_number = generate_invoice_number()

    transaction_data = {
        "invoice_number": invoice_number,
        "customer_id": body.customer_id,
        "customer_name": body.customer_name,
        "customer_phone": body.customer_phone,
        "created_by": current_user["id"],
        "transaction_date": (body.transaction_date or date.today()).isoformat(),
        "due_date": body.due_date.isoformat() if body.due_date else None,
        "subtotal": float(body.subtotal),
        "discount": float(body.discount),
        "total_amount": float(body.total_amount),
        "amount_paid": float(body.amount_paid),
        "payment_status": body.payment_status.value,
        "payment_method": body.payment_method.value if body.payment_method else None,
        "notes": body.notes,
    }

    result = db.table("transactions").insert(transaction_data).execute()
    transaction = result.data[0]

    # Insert line items
    items_data = []
    for item in body.items:
        items_data.append({
            "transaction_id": transaction["id"],
            "product_id": item.product_id,
            "product_name": item.product_name,
            "quantity": item.quantity,
            "unit_price": float(item.unit_price),
            "line_total": float(item.line_total),
        })

    items_result = db.table("transaction_items").insert(items_data).execute()

    # Update customer pending balance
    if body.payment_status.value in ("pending", "partial"):
        pending_amount = float(body.total_amount) - float(body.amount_paid)
        # Fetch current pending
        cust = db.table("customers").select("total_pending").eq("id", body.customer_id).execute()
        if cust.data:
            current_pending = float(cust.data[0].get("total_pending", 0))
            db.table("customers").update({
                "total_pending": current_pending + pending_amount,
                "updated_at": datetime.now(timezone.utc).isoformat(),
            }).eq("id", body.customer_id).execute()

    # Generate invoice PDF
    try:
        pdf_url = await generate_invoice_pdf(transaction["id"])
        if pdf_url:
            db.table("transactions").update({"invoice_pdf_url": pdf_url}).eq("id", transaction["id"]).execute()
            transaction["invoice_pdf_url"] = pdf_url
    except Exception as e:
        pass  # PDF generation failure shouldn't block the transaction

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="CREATE_TRANSACTION",
        entity_type="transaction",
        entity_id=transaction["id"],
        new_value={"invoice_number": invoice_number, "total_amount": float(body.total_amount)},
    )

    items = [TransactionItemResponse(**item) for item in items_result.data]
    return TransactionResponse(**transaction, items=items)


@router.get("/{transaction_id}", response_model=TransactionResponse)
async def get_transaction(transaction_id: str, current_user: dict = Depends(get_current_user)):
    db = get_supabase()
    result = db.table("transactions").select("*").eq("id", transaction_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Transaction not found")

    t = result.data[0]

    # Access control
    if current_user["role"] == "salesman" and t["created_by"] != current_user["id"]:
        raise HTTPException(status_code=403, detail="Access denied")

    items_result = db.table("transaction_items").select("*").eq("transaction_id", transaction_id).execute()
    items = [TransactionItemResponse(**item) for item in items_result.data]

    # Fetch user name for this single transaction
    user_result = db.table("users").select("full_name").eq("id", t["created_by"]).execute()
    created_by_name = user_result.data[0]["full_name"] if user_result.data else None

    return TransactionResponse(**t, created_by_name=created_by_name, items=items)


@router.put("/{transaction_id}", response_model=TransactionResponse)
async def update_transaction(
    transaction_id: str, body: TransactionUpdate,
    current_user: dict = Depends(require_admin_or_manager),
):
    db = get_supabase()

    old_result = db.table("transactions").select("*").eq("id", transaction_id).execute()
    if not old_result.data:
        raise HTTPException(status_code=404, detail="Transaction not found")

    old_txn = old_result.data[0]
    update_data = body.model_dump(exclude_none=True)
    if "payment_status" in update_data:
        update_data["payment_status"] = update_data["payment_status"].value if hasattr(update_data["payment_status"], "value") else update_data["payment_status"]
    if "payment_method" in update_data:
        update_data["payment_method"] = update_data["payment_method"].value if hasattr(update_data["payment_method"], "value") else update_data["payment_method"]
    update_data["updated_at"] = datetime.now(timezone.utc).isoformat()

    db.table("transactions").update(update_data).eq("id", transaction_id).execute()

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="UPDATE_TRANSACTION",
        entity_type="transaction",
        entity_id=transaction_id,
        old_value={k: old_txn.get(k) for k in update_data.keys()},
        new_value=update_data,
    )

    return await get_transaction(transaction_id, current_user)


@router.delete("/{transaction_id}")
async def void_transaction(transaction_id: str, current_user: dict = Depends(require_admin)):
    db = get_supabase()

    result = db.table("transactions").select("*").eq("id", transaction_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Transaction not found")

    txn = result.data[0]

    if txn["payment_status"] == "voided":
        raise HTTPException(status_code=400, detail="Transaction already voided")

    # Reverse pending balance on customer
    if txn["payment_status"] in ("pending", "partial"):
        outstanding = float(txn["total_amount"]) - float(txn["amount_paid"])
        cust = db.table("customers").select("total_pending").eq("id", txn["customer_id"]).execute()
        if cust.data:
            new_pending = max(0, float(cust.data[0].get("total_pending", 0)) - outstanding)
            db.table("customers").update({
                "total_pending": new_pending
            }).eq("id", txn["customer_id"]).execute()

    db.table("transactions").update({
        "payment_status": "voided",
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }).eq("id", transaction_id).execute()

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="VOID_TRANSACTION",
        entity_type="transaction",
        entity_id=transaction_id,
        old_value={"payment_status": txn["payment_status"]},
        new_value={"payment_status": "voided"},
    )

    return {"message": "Transaction voided successfully"}


@router.post("/{transaction_id}/collect-payment", response_model=PaymentCollectionResponse)
async def collect_payment(
    transaction_id: str, body: CollectPaymentRequest,
    current_user: dict = Depends(get_current_user),
):
    db = get_supabase()

    txn_result = db.table("transactions").select("*").eq("id", transaction_id).execute()
    if not txn_result.data:
        raise HTTPException(status_code=404, detail="Transaction not found")

    txn = txn_result.data[0]

    if txn["payment_status"] == "paid":
        raise HTTPException(status_code=400, detail="Transaction is already fully paid")
    if txn["payment_status"] == "voided":
        raise HTTPException(status_code=400, detail="Cannot collect payment on voided transaction")

    outstanding = float(txn["total_amount"]) - float(txn["amount_paid"])
    if body.amount > outstanding:
        raise HTTPException(status_code=400, detail=f"Amount exceeds outstanding balance of {outstanding}")

    # Record payment collection
    collection_data = {
        "transaction_id": transaction_id,
        "collected_by": current_user["id"],
        "amount": float(body.amount),
        "payment_method": body.payment_method.value,
        "notes": body.notes,
    }
    collection_result = db.table("payment_collections").insert(collection_data).execute()

    # Update transaction
    new_paid = float(txn["amount_paid"]) + float(body.amount)
    new_status = "paid" if new_paid >= float(txn["total_amount"]) else "partial"

    db.table("transactions").update({
        "amount_paid": new_paid,
        "payment_status": new_status,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }).eq("id", transaction_id).execute()

    # Update customer pending balance
    cust = db.table("customers").select("total_pending").eq("id", txn["customer_id"]).execute()
    if cust.data:
        new_pending = max(0, float(cust.data[0].get("total_pending", 0)) - float(body.amount))
        db.table("customers").update({
            "total_pending": new_pending,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }).eq("id", txn["customer_id"]).execute()

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="COLLECT_PAYMENT",
        entity_type="transaction",
        entity_id=transaction_id,
        new_value={
            "amount": float(body.amount),
            "new_total_paid": new_paid,
            "new_status": new_status,
        },
    )

    return PaymentCollectionResponse(**collection_result.data[0])


@router.get("/{transaction_id}/invoice")
async def get_invoice(transaction_id: str, current_user: dict = Depends(get_current_user)):
    db = get_supabase()
    result = db.table("transactions").select("invoice_pdf_url").eq("id", transaction_id).execute()
    if not result.data or not result.data[0].get("invoice_pdf_url"):
        raise HTTPException(status_code=404, detail="Invoice not found")
    return {"invoice_url": result.data[0]["invoice_pdf_url"]}


@router.post("/{transaction_id}/regenerate-invoice")
async def regenerate_invoice(transaction_id: str, current_user: dict = Depends(get_current_user)):
    pdf_url = await generate_invoice_pdf(transaction_id)
    if not pdf_url:
        raise HTTPException(status_code=500, detail="Failed to generate invoice")

    db = get_supabase()
    db.table("transactions").update({"invoice_pdf_url": pdf_url}).eq("id", transaction_id).execute()
    return {"invoice_url": pdf_url, "message": "Invoice regenerated successfully"}
