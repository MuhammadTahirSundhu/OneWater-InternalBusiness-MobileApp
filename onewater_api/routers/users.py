from fastapi import APIRouter, Depends, HTTPException, status
from datetime import datetime, timezone
from passlib.context import CryptContext
from dependencies import get_supabase, require_admin
from models.user import UserCreate, UserUpdate, UserResponse
from utils.audit_writer import write_audit

router = APIRouter()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


@router.get("/", response_model=list[UserResponse])
async def list_users(current_user: dict = Depends(require_admin)):
    db = get_supabase()
    result = db.table("users").select("*").order("created_at", desc=True).execute()
    return [UserResponse(**u) for u in result.data]


@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(body: UserCreate, current_user: dict = Depends(require_admin)):
    db = get_supabase()

    # Check if phone already exists
    existing = db.table("users").select("id").eq("phone", body.phone).execute()
    if existing.data:
        raise HTTPException(status_code=400, detail="Phone number already registered")

    password_hash = pwd_context.hash(body.password)

    user_data = {
        "full_name": body.full_name,
        "phone": body.phone,
        "email": body.email,
        "role": body.role.value,
        "password_hash": password_hash,
        "is_active": True,
        "onboarding_done": False,
    }

    result = db.table("users").insert(user_data).execute()
    new_user = result.data[0]

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="CREATE_USER",
        entity_type="user",
        entity_id=new_user["id"],
        new_value={"full_name": body.full_name, "phone": body.phone, "role": body.role.value},
    )

    return UserResponse(**new_user)


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: str, current_user: dict = Depends(require_admin)):
    db = get_supabase()
    result = db.table("users").select("*").eq("id", user_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse(**result.data[0])


@router.put("/{user_id}", response_model=UserResponse)
async def update_user(user_id: str, body: UserUpdate, current_user: dict = Depends(require_admin)):
    db = get_supabase()

    old_result = db.table("users").select("*").eq("id", user_id).execute()
    if not old_result.data:
        raise HTTPException(status_code=404, detail="User not found")

    old_user = old_result.data[0]
    update_data = body.model_dump(exclude_none=True)
    if "role" in update_data:
        update_data["role"] = update_data["role"].value if hasattr(update_data["role"], "value") else update_data["role"]
    update_data["updated_at"] = datetime.now(timezone.utc).isoformat()

    db.table("users").update(update_data).eq("id", user_id).execute()

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="UPDATE_USER",
        entity_type="user",
        entity_id=user_id,
        old_value={"role": old_user["role"], "is_active": old_user["is_active"]},
        new_value=update_data,
    )

    result = db.table("users").select("*").eq("id", user_id).execute()
    return UserResponse(**result.data[0])


@router.delete("/{user_id}")
async def deactivate_user(user_id: str, current_user: dict = Depends(require_admin)):
    db = get_supabase()

    result = db.table("users").select("*").eq("id", user_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="User not found")

    if result.data[0]["role"] == "admin" and user_id != current_user["id"]:
        # Check if this is the last admin
        admins = db.table("users").select("id").eq("role", "admin").eq("is_active", True).execute()
        if len(admins.data) <= 1:
            raise HTTPException(status_code=400, detail="Cannot deactivate the last admin")

    db.table("users").update({
        "is_active": False,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }).eq("id", user_id).execute()

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="DEACTIVATE_USER",
        entity_type="user",
        entity_id=user_id,
    )

    return {"message": "User deactivated successfully"}
