from fastapi import APIRouter, Depends, HTTPException
from dependencies import get_supabase, require_admin
from models.audit import BusinessSettingResponse, BusinessSettingUpdate
from utils.audit_writer import write_audit
from datetime import datetime, timezone

router = APIRouter()


@router.get("/", response_model=list[BusinessSettingResponse])
async def list_settings(current_user: dict = Depends(require_admin)):
    db = get_supabase()
    result = db.table("business_settings").select("*").order("key").execute()
    return [BusinessSettingResponse(**s) for s in result.data]


@router.put("/{key}", response_model=BusinessSettingResponse)
async def update_setting(key: str, body: BusinessSettingUpdate, current_user: dict = Depends(require_admin)):
    db = get_supabase()

    existing = db.table("business_settings").select("*").eq("key", key).execute()

    if existing.data:
        old_value = existing.data[0].get("value")
        db.table("business_settings").update({
            "value": body.value,
            "updated_by": current_user["id"],
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }).eq("key", key).execute()
    else:
        old_value = None
        db.table("business_settings").insert({
            "key": key,
            "value": body.value,
            "updated_by": current_user["id"],
        }).execute()

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="UPDATE_BUSINESS_SETTINGS",
        entity_type="settings",
        entity_id=key,
        old_value=old_value,
        new_value=body.value,
    )

    result = db.table("business_settings").select("*").eq("key", key).execute()
    return BusinessSettingResponse(**result.data[0])
