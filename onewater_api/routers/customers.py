from fastapi import APIRouter, Depends, HTTPException, Query, status
from datetime import datetime, timezone
from dependencies import get_supabase, get_current_user
from models.customer import CustomerCreate, CustomerUpdate, CustomerResponse
from utils.audit_writer import write_audit

router = APIRouter()


@router.get("/", response_model=list[CustomerResponse])
async def list_customers(
    search: str = Query(None, description="Search by name or phone"),
    has_pending: bool = Query(None, description="Filter customers with pending balance"),
    current_user: dict = Depends(get_current_user),
):
    db = get_supabase()
    query = db.table("customers").select("*").order("created_at", desc=True)

    if search:
        query = query.or_(f"name.ilike.%{search}%,phone.ilike.%{search}%")

    if has_pending is True:
        query = query.gt("total_pending", 0)

    result = query.execute()
    return [CustomerResponse(**c) for c in result.data]


@router.post("/", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
async def create_customer(body: CustomerCreate, current_user: dict = Depends(get_current_user)):
    db = get_supabase()

    customer_data = body.model_dump(exclude_none=True)
    customer_data["created_by"] = current_user["id"]

    result = db.table("customers").insert(customer_data).execute()
    new_customer = result.data[0]

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="CREATE_CUSTOMER",
        entity_type="customer",
        entity_id=new_customer["id"],
        new_value=customer_data,
    )

    return CustomerResponse(**new_customer)


@router.get("/pending", response_model=list[CustomerResponse])
async def get_pending_customers(current_user: dict = Depends(get_current_user)):
    db = get_supabase()
    result = db.table("customers").select("*").gt("total_pending", 0).order("total_pending", desc=True).execute()
    return [CustomerResponse(**c) for c in result.data]


@router.get("/{customer_id}", response_model=CustomerResponse)
async def get_customer(customer_id: str, current_user: dict = Depends(get_current_user)):
    db = get_supabase()
    result = db.table("customers").select("*").eq("id", customer_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Customer not found")
    return CustomerResponse(**result.data[0])


@router.put("/{customer_id}", response_model=CustomerResponse)
async def update_customer(customer_id: str, body: CustomerUpdate, current_user: dict = Depends(get_current_user)):
    db = get_supabase()

    old_result = db.table("customers").select("*").eq("id", customer_id).execute()
    if not old_result.data:
        raise HTTPException(status_code=404, detail="Customer not found")

    update_data = body.model_dump(exclude_none=True)
    update_data["updated_at"] = datetime.now(timezone.utc).isoformat()

    db.table("customers").update(update_data).eq("id", customer_id).execute()

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="UPDATE_CUSTOMER",
        entity_type="customer",
        entity_id=customer_id,
        old_value={k: old_result.data[0].get(k) for k in update_data.keys()},
        new_value=update_data,
    )

    result = db.table("customers").select("*").eq("id", customer_id).execute()
    return CustomerResponse(**result.data[0])


@router.get("/{customer_id}/transactions")
async def get_customer_transactions(
    customer_id: str,
    limit: int = Query(10, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user),
):
    db = get_supabase()
    result = db.table("transactions").select("*").eq(
        "customer_id", customer_id
    ).order("transaction_date", desc=True).range(offset, offset + limit - 1).execute()
    return result.data
