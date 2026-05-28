import logging
from datetime import date, timedelta
from dependencies import get_supabase

logger = logging.getLogger(__name__)


def send_overdue_payment_summary() -> dict:
    """Check for overdue payments and create a notification."""
    try:
        db = get_supabase()
        seven_days_ago = (date.today() - timedelta(days=7)).isoformat()

        result = db.table("transactions").select(
            "customer_name,total_amount,amount_paid,transaction_date"
        ).in_(
            "payment_status", ["pending", "partial"]
        ).lte("transaction_date", seven_days_ago).execute()

        if not result.data:
            return {"message": "No overdue payments found", "count": 0}

        total_overdue = sum(
            float(t["total_amount"]) - float(t["amount_paid"]) for t in result.data
        )
        customer_names = list(set(t["customer_name"] for t in result.data))

        notification_data = {
            "type": "overdue_payment_summary",
            "title": "Weekly Payment Reminder",
            "body": f"{len(result.data)} transactions from {len(customer_names)} customers "
                    f"have overdue payments totaling PKR {total_overdue:,.0f}",
            "target_roles": ["admin", "manager"],
            "is_read": False,
            "related_data": {
                "count": len(result.data),
                "total_amount": total_overdue,
                "customers": customer_names[:10],
            },
        }

        db.table("notifications").insert(notification_data).execute()

        logger.info(f"Overdue notification created: {len(result.data)} transactions, PKR {total_overdue:,.0f}")
        return {
            "message": "Overdue check completed",
            "count": len(result.data),
            "total_overdue": total_overdue,
        }

    except Exception as e:
        logger.error(f"Overdue check failed: {e}", exc_info=True)
        return {"message": f"Error: {str(e)}", "count": 0}
