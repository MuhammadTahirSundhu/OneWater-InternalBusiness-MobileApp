from fastapi import APIRouter, Depends, Query
from datetime import date, datetime, timedelta, timezone
from typing import Optional
from dependencies import get_supabase, require_admin_or_manager, get_current_user

router = APIRouter()


def _parse_date_range(
    preset: Optional[str] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
):
    """Resolve date range from either preset or explicit date_from/date_to."""
    today = date.today()
    if preset == "today":
        return today.isoformat(), today.isoformat()
    elif preset == "yesterday":
        y = today - timedelta(days=1)
        return y.isoformat(), y.isoformat()
    elif preset == "last_7_days":
        return (today - timedelta(days=6)).isoformat(), today.isoformat()
    elif preset == "last_30_days":
        return (today - timedelta(days=29)).isoformat(), today.isoformat()
    elif preset == "this_month":
        return today.replace(day=1).isoformat(), today.isoformat()
    elif preset == "last_month":
        first_this = today.replace(day=1)
        last_prev = first_this - timedelta(days=1)
        first_prev = last_prev.replace(day=1)
        return first_prev.isoformat(), last_prev.isoformat()
    else:
        # Custom or no preset — use explicit dates or default to last 30 days
        df = date_from.isoformat() if date_from else (today - timedelta(days=29)).isoformat()
        dt = date_to.isoformat() if date_to else today.isoformat()
        return df, dt


@router.get("/summary")
async def get_summary(
    preset: Optional[str] = Query(None),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    current_user: dict = Depends(require_admin_or_manager),
):
    db = get_supabase()
    today = date.today().isoformat()
    month_start = date.today().replace(day=1).isoformat()

    # Today's sales
    today_result = db.table("transactions").select("total_amount,payment_status").eq(
        "transaction_date", today
    ).neq("payment_status", "voided").execute()
    today_total = sum(float(t["total_amount"]) for t in today_result.data)
    today_count = len(today_result.data)

    # This month totals
    month_result = db.table("transactions").select("total_amount,amount_paid,payment_status").gte(
        "transaction_date", month_start
    ).neq("payment_status", "voided").execute()
    month_total = sum(float(t["total_amount"]) for t in month_result.data)
    month_collected = sum(float(t["amount_paid"]) for t in month_result.data)

    # All-time pending
    pending_result = db.table("transactions").select("total_amount,amount_paid").in_(
        "payment_status", ["pending", "partial"]
    ).execute()
    total_pending = sum(float(t["total_amount"]) - float(t["amount_paid"]) for t in pending_result.data)
    pending_count = len(pending_result.data)

    # Pending customers
    pending_customers = db.table("customers").select("id").gt("total_pending", 0).execute()

    # Today's expenses
    today_expenses_result = db.table("expenses").select("amount").eq(
        "expense_date", today
    ).execute()
    today_expenses = sum(float(e["amount"]) for e in today_expenses_result.data)

    # Month expenses
    month_expenses_result = db.table("expenses").select("amount").gte(
        "expense_date", month_start
    ).execute()
    month_expenses = sum(float(e["amount"]) for e in month_expenses_result.data)
    total_expenses = month_expenses  # for dashboard display

    # Today's amount in
    today_amount_in_result = db.table("amount_in").select("amount").eq(
        "recorded_date", today
    ).execute()
    today_amount_in = sum(float(a["amount"]) for a in today_amount_in_result.data)

    # Month amount in
    month_amount_in_result = db.table("amount_in").select("amount").gte(
        "recorded_date", month_start
    ).execute()
    month_amount_in = sum(float(a["amount"]) for a in month_amount_in_result.data)

    return {
        "today_sales": today_total,
        "today_transactions": today_count,
        "month_sales": month_total,
        "month_collected": month_collected,
        "total_pending": total_pending,
        "pending_transactions": pending_count,
        "pending_customers": len(pending_customers.data),
        # Expenses
        "today_expenses": today_expenses,
        "month_expenses": month_expenses,
        "total_expenses": total_expenses,
        # Amount In
        "today_amount_in": today_amount_in,
        "month_amount_in": month_amount_in,
        # Net calculation: collections + amount_in - expenses
        "month_net": month_collected + month_amount_in - month_expenses,
    }


@router.get("/sales-by-period")
async def sales_by_period(
    preset: Optional[str] = Query("last_7_days"),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    current_user: dict = Depends(require_admin_or_manager),
):
    db = get_supabase()
    start_date, end_date = _parse_date_range(preset, date_from, date_to)

    result = db.table("transactions").select(
        "transaction_date,total_amount"
    ).gte("transaction_date", start_date).lte(
        "transaction_date", end_date
    ).neq("payment_status", "voided").order("transaction_date").execute()

    daily_data = {}
    for t in result.data:
        d = t["transaction_date"]
        daily_data[d] = daily_data.get(d, 0) + float(t["total_amount"])

    return {
        "preset": preset,
        "date_from": start_date,
        "date_to": end_date,
        "data": [{"date": k, "amount": v} for k, v in sorted(daily_data.items())],
    }


@router.get("/sales-by-product")
async def sales_by_product(
    preset: Optional[str] = Query("last_30_days"),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    current_user: dict = Depends(require_admin_or_manager),
):
    db = get_supabase()
    start_date, end_date = _parse_date_range(preset, date_from, date_to)

    # Get transaction IDs within date range
    txn_result = db.table("transactions").select("id").gte(
        "transaction_date", start_date
    ).lte("transaction_date", end_date).neq("payment_status", "voided").execute()

    txn_ids = [t["id"] for t in txn_result.data]
    if not txn_ids:
        return []

    result = db.table("transaction_items").select("product_name,line_total,quantity").in_(
        "transaction_id", txn_ids
    ).execute()

    product_data = {}
    for item in result.data:
        name = item["product_name"]
        if name not in product_data:
            product_data[name] = {"revenue": 0, "quantity": 0}
        product_data[name]["revenue"] += float(item["line_total"])
        product_data[name]["quantity"] += int(item["quantity"])

    return [{"product": k, **v} for k, v in sorted(product_data.items(), key=lambda x: -x[1]["revenue"])]


@router.get("/payment-status")
async def payment_status_breakdown(
    preset: Optional[str] = Query("last_30_days"),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    current_user: dict = Depends(require_admin_or_manager),
):
    db = get_supabase()
    start_date, end_date = _parse_date_range(preset, date_from, date_to)

    result = db.table("transactions").select("payment_status,total_amount").gte(
        "transaction_date", start_date
    ).lte("transaction_date", end_date).neq("payment_status", "voided").execute()

    breakdown = {"paid": 0, "pending": 0, "partial": 0}
    counts = {"paid": 0, "pending": 0, "partial": 0}

    for t in result.data:
        s = t["payment_status"]
        if s in breakdown:
            breakdown[s] += float(t["total_amount"])
            counts[s] += 1

    total = sum(breakdown.values()) or 1
    return {
        "date_from": start_date,
        "date_to": end_date,
        "breakdown": [
            {"status": k, "amount": v, "percentage": round(v / total * 100, 1), "count": counts[k]}
            for k, v in breakdown.items()
        ],
    }


@router.get("/top-customers")
async def top_customers(
    limit: int = Query(10, ge=1, le=50),
    preset: Optional[str] = Query("last_30_days"),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    current_user: dict = Depends(require_admin_or_manager),
):
    db = get_supabase()
    start_date, end_date = _parse_date_range(preset, date_from, date_to)

    result = db.table("transactions").select(
        "customer_id,customer_name,total_amount"
    ).gte("transaction_date", start_date).lte(
        "transaction_date", end_date
    ).neq("payment_status", "voided").execute()

    customer_totals = {}
    for t in result.data:
        cid = t["customer_id"]
        if cid not in customer_totals:
            customer_totals[cid] = {"name": t["customer_name"], "total": 0, "count": 0}
        customer_totals[cid]["total"] += float(t["total_amount"])
        customer_totals[cid]["count"] += 1

    sorted_customers = sorted(customer_totals.values(), key=lambda x: x["total"], reverse=True)
    return sorted_customers[:limit]


@router.get("/overdue")
async def overdue_transactions(current_user: dict = Depends(require_admin_or_manager)):
    db = get_supabase()
    seven_days_ago = (date.today() - timedelta(days=7)).isoformat()

    result = db.table("transactions").select("*").in_(
        "payment_status", ["pending", "partial"]
    ).lte("transaction_date", seven_days_ago).order("transaction_date").execute()

    return result.data


@router.get("/revenue-trend")
async def revenue_trend(
    preset: Optional[str] = Query("last_7_days"),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    current_user: dict = Depends(require_admin_or_manager),
):
    db = get_supabase()
    start_date, end_date = _parse_date_range(preset, date_from, date_to)

    result = db.table("transactions").select(
        "transaction_date,total_amount,amount_paid"
    ).gte("transaction_date", start_date).lte(
        "transaction_date", end_date
    ).neq("payment_status", "voided").order("transaction_date").execute()

    daily = {}
    for t in result.data:
        d = t["transaction_date"]
        if d not in daily:
            daily[d] = {"revenue": 0, "collected": 0}
        daily[d]["revenue"] += float(t["total_amount"])
        daily[d]["collected"] += float(t["amount_paid"])

    return [{"date": k, **v} for k, v in sorted(daily.items())]


@router.get("/collection-efficiency")
async def collection_efficiency(
    preset: Optional[str] = Query("this_month"),
    current_user: dict = Depends(require_admin_or_manager),
):
    db = get_supabase()
    start_date, end_date = _parse_date_range(preset)

    result = db.table("transactions").select(
        "total_amount,amount_paid"
    ).gte("transaction_date", start_date).lte(
        "transaction_date", end_date
    ).neq("payment_status", "voided").execute()

    total_invoiced = sum(float(t["total_amount"]) for t in result.data)
    total_collected = sum(float(t["amount_paid"]) for t in result.data)

    efficiency = round((total_collected / total_invoiced * 100), 1) if total_invoiced > 0 else 0

    return {
        "date_from": start_date,
        "date_to": end_date,
        "total_invoiced": total_invoiced,
        "total_collected": total_collected,
        "efficiency_percentage": efficiency,
    }
