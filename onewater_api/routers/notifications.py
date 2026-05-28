from fastapi import APIRouter, Depends, HTTPException, Query
from dependencies import get_supabase, get_current_user, require_admin
from models.audit import NotificationResponse
from utils.audit_writer import write_audit

router = APIRouter()


@router.get("/", response_model=list[NotificationResponse])
async def list_notifications(
    unread_only: bool = Query(False),
    limit: int = Query(50, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    db = get_supabase()
    query = db.table("notifications").select("*").contains(
        "target_roles", [current_user["role"]]
    ).order("created_at", desc=True).limit(limit)

    if unread_only:
        query = query.eq("is_read", False)

    result = query.execute()
    return [NotificationResponse(**n) for n in result.data]


@router.put("/{notification_id}/read")
async def mark_read(notification_id: str, current_user: dict = Depends(get_current_user)):
    db = get_supabase()
    db.table("notifications").update({"is_read": True}).eq("id", notification_id).execute()
    return {"message": "Notification marked as read"}


@router.post("/mark-all-read")
async def mark_all_read(current_user: dict = Depends(get_current_user)):
    db = get_supabase()
    db.table("notifications").update({"is_read": True}).contains(
        "target_roles", [current_user["role"]]
    ).eq("is_read", False).execute()
    return {"message": "All notifications marked as read"}


@router.post("/trigger-overdue-check")
async def trigger_overdue_check(current_user: dict = Depends(require_admin)):
    from services.notification_service import send_overdue_payment_summary
    result = send_overdue_payment_summary()

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="TRIGGER_OVERDUE_CHECK",
        entity_type="notification",
    )

    return result
