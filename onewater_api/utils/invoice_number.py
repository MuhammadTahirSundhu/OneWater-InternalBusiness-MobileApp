import logging
from dependencies import get_supabase
from config import get_settings

logger = logging.getLogger(__name__)


def generate_invoice_number() -> str:
    """Generate sequential invoice number like OW-2025-000001."""
    settings = get_settings()
    db = get_supabase()
    prefix = settings.invoice_prefix

    # Get or create the invoice counter from business_settings
    result = db.table("business_settings").select("*").eq("key", "invoice_counter").execute()

    if result.data and len(result.data) > 0:
        current_count = result.data[0]["value"].get("counter", 0)
        new_count = current_count + 1
        db.table("business_settings").update({
            "value": {"counter": new_count}
        }).eq("key", "invoice_counter").execute()
    else:
        new_count = settings.invoice_start_number
        db.table("business_settings").insert({
            "key": "invoice_counter",
            "value": {"counter": new_count}
        }).execute()

    from datetime import datetime
    year = datetime.now().year
    return f"{prefix}-{year}-{new_count:06d}"
