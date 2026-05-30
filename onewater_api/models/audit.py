from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class AuditLogResponse(BaseModel):
    id: str
    user_id: Optional[str] = None
    user_name: str
    action: str
    entity_type: str
    entity_id: Optional[str] = None
    old_value: Optional[dict] = None
    new_value: Optional[dict] = None
    ip_address: Optional[str] = None
    device_info: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class NotificationResponse(BaseModel):
    id: str
    type: str
    title: str
    body: str
    target_roles: list[str] = []
    is_read: bool
    related_data: Optional[dict] = None
    created_at: datetime

    class Config:
        from_attributes = True


from typing import Optional, Any

class BusinessSettingResponse(BaseModel):
    id: str
    key: str
    value: Any
    updated_by: Optional[str] = None
    updated_at: datetime

    class Config:
        from_attributes = True


class BusinessSettingUpdate(BaseModel):
    value: Any
