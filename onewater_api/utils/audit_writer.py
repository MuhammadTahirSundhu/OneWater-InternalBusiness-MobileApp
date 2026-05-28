import logging
from dependencies import get_supabase

logger = logging.getLogger(__name__)


async def write_audit(
    user_id: str,
    user_name: str,
    action: str,
    entity_type: str,
    entity_id: str = None,
    old_value: dict = None,
    new_value: dict = None,
    ip_address: str = None,
    device_info: str = None,
):
    """Write an audit log entry to the database."""
    try:
        db = get_supabase()
        data = {
            "user_id": user_id,
            "user_name": user_name,
            "action": action,
            "entity_type": entity_type,
            "entity_id": entity_id,
            "old_value": old_value,
            "new_value": new_value,
            "ip_address": ip_address,
            "device_info": device_info,
        }
        db.table("audit_logs").insert(data).execute()
    except Exception as e:
        logger.error(f"Failed to write audit log: {e}")
