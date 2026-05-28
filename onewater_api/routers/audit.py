from fastapi import APIRouter, Depends, Query
from typing import Optional
from datetime import date
from dependencies import get_supabase, require_admin
from models.audit import AuditLogResponse

router = APIRouter()


@router.get("/", response_model=list[AuditLogResponse])
async def list_audit_logs(
    user_id: Optional[str] = Query(None),
    action: Optional[str] = Query(None),
    entity_type: Optional[str] = Query(None),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(require_admin),
):
    db = get_supabase()
    query = db.table("audit_logs").select("*").order("created_at", desc=True)

    if user_id:
        query = query.eq("user_id", user_id)
    if action:
        query = query.eq("action", action)
    if entity_type:
        query = query.eq("entity_type", entity_type)
    if date_from:
        query = query.gte("created_at", f"{date_from.isoformat()}T00:00:00Z")
    if date_to:
        query = query.lte("created_at", f"{date_to.isoformat()}T23:59:59Z")

    result = query.range(offset, offset + limit - 1).execute()
    return [AuditLogResponse(**log) for log in result.data]


@router.get("/{log_id}", response_model=AuditLogResponse)
async def get_audit_log(log_id: str, current_user: dict = Depends(require_admin)):
    db = get_supabase()
    result = db.table("audit_logs").select("*").eq("id", log_id).execute()
    if not result.data:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Audit log not found")
    return AuditLogResponse(**result.data[0])
