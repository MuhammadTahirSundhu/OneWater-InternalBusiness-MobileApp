from fastapi import APIRouter, Depends, HTTPException, status
from datetime import datetime, timezone
from dependencies import get_supabase, get_current_user, require_admin
from models.product import ProductCreate, ProductUpdate, ProductResponse
from utils.audit_writer import write_audit

router = APIRouter()


@router.get("/", response_model=list[ProductResponse])
async def list_products(current_user: dict = Depends(get_current_user)):
    """List all products. Accessible by all authenticated users.
    Salesmen only see active products; admins/managers see all."""
    db = get_supabase()
    query = db.table("products").select("*").order("created_at")

    # Salesmen only see active products
    if current_user["role"] == "salesman":
        query = query.eq("is_active", True)

    result = query.execute()
    return [ProductResponse(**p) for p in result.data]


@router.post("/", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
async def create_product(body: ProductCreate, current_user: dict = Depends(require_admin)):
    db = get_supabase()

    existing = db.table("products").select("id").eq("sku", body.sku).execute()
    if existing.data:
        raise HTTPException(status_code=400, detail="SKU already exists")

    product_data = body.model_dump()
    product_data["category"] = product_data["category"].value if hasattr(product_data["category"], "value") else product_data["category"]

    result = db.table("products").insert(product_data).execute()
    new_product = result.data[0]

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="CREATE_PRODUCT",
        entity_type="product",
        entity_id=new_product["id"],
        new_value=product_data,
    )

    return ProductResponse(**new_product)


@router.put("/{product_id}", response_model=ProductResponse)
async def update_product(product_id: str, body: ProductUpdate, current_user: dict = Depends(require_admin)):
    db = get_supabase()

    old_result = db.table("products").select("*").eq("id", product_id).execute()
    if not old_result.data:
        raise HTTPException(status_code=404, detail="Product not found")

    update_data = body.model_dump(exclude_none=True)
    if "category" in update_data:
        update_data["category"] = update_data["category"].value if hasattr(update_data["category"], "value") else update_data["category"]
    update_data["updated_at"] = datetime.now(timezone.utc).isoformat()

    db.table("products").update(update_data).eq("id", product_id).execute()

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="UPDATE_PRODUCT",
        entity_type="product",
        entity_id=product_id,
        old_value={k: old_result.data[0].get(k) for k in update_data.keys()},
        new_value=update_data,
    )

    result = db.table("products").select("*").eq("id", product_id).execute()
    return ProductResponse(**result.data[0])


@router.delete("/{product_id}")
async def deactivate_product(product_id: str, current_user: dict = Depends(require_admin)):
    db = get_supabase()

    result = db.table("products").select("*").eq("id", product_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Product not found")

    db.table("products").update({
        "is_active": False,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }).eq("id", product_id).execute()

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="DEACTIVATE_PRODUCT",
        entity_type="product",
        entity_id=product_id,
    )

    return {"message": "Product deactivated successfully"}
