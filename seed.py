"""
OneWater Pakistan — Seed Script
Creates sample users, products, customers, and transactions.
Run: python seed.py
"""
import os
import sys
from datetime import date, timedelta
from passlib.context import CryptContext
from supabase import create_client

# Load env
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), "onewater_api", ".env"))

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("ERROR: Set SUPABASE_URL and SUPABASE_SERVICE_KEY in onewater_api/.env")
    sys.exit(1)

db = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def seed():
    print("🌊 Seeding OneWater Pakistan database...")

    # === Users ===
    users_data = [
        {
            "full_name": "Tahir Admin",
            "phone": "03001234567",
            "email": "admin@onewaterpakistan.com",
            "role": "admin",
            "password_hash": pwd_context.hash("Admin@123"),
            "is_active": True,
            "onboarding_done": True,
        },
        {
            "full_name": "Ali Manager",
            "phone": "03009876543",
            "email": "manager@onewaterpakistan.com",
            "role": "manager",
            "password_hash": pwd_context.hash("Manager@123"),
            "is_active": True,
            "onboarding_done": False,
        },
        {
            "full_name": "Hassan Sales",
            "phone": "03005551234",
            "email": "sales@onewaterpakistan.com",
            "role": "salesman",
            "password_hash": pwd_context.hash("Sales@123"),
            "is_active": True,
            "onboarding_done": False,
        },
    ]

    print("  Creating users...")
    users_result = db.table("users").insert(users_data).execute()
    users = {u["role"]: u for u in users_result.data}
    admin_id = users["admin"]["id"]
    manager_id = users["manager"]["id"]
    salesman_id = users["salesman"]["id"]
    print(f"  ✅ Created {len(users_result.data)} users")

    # === Products ===
    products_data = [
        {
            "name": "500ml Bottle Pack (24 pcs)",
            "sku": "OW-500ML-24",
            "category": "bottle_pack_500ml",
            "unit_price": 600,
            "security_deposit": 0,
        },
        {
            "name": "1.5L Bottle",
            "sku": "OW-1500ML",
            "category": "bottle_1_5L",
            "unit_price": 80,
            "security_deposit": 0,
        },
        {
            "name": "19L Bottle (New)",
            "sku": "OW-19L-NEW",
            "category": "bottle_19L_new",
            "unit_price": 2500,
            "security_deposit": 1000,
        },
        {
            "name": "19L Bottle (Refill)",
            "sku": "OW-19L-REFILL",
            "category": "bottle_19L_refill",
            "unit_price": 450,
            "security_deposit": 0,
        },
    ]

    print("  Creating products...")
    products_result = db.table("products").insert(products_data).execute()
    products = {p["category"]: p for p in products_result.data}
    print(f"  ✅ Created {len(products_result.data)} products")

    # === Customers ===
    customers_data = [
        {"name": "Ahmed Khan", "phone": "03211112222", "address": "Blue Area, Islamabad", "area": "Blue Area", "created_by": admin_id},
        {"name": "Sara Office Supplies", "phone": "03213334444", "address": "F-8 Markaz, Islamabad", "area": "F-8", "created_by": admin_id},
        {"name": "Islamabad Grammar School", "phone": "03215556666", "address": "G-10/2, Islamabad", "area": "G-10", "created_by": manager_id},
        {"name": "Fatima Restaurant", "phone": "03217778888", "address": "F-7 Markaz, Islamabad", "area": "F-7", "created_by": salesman_id},
        {"name": "Bilal Grocery Store", "phone": "03219990000", "address": "G-11 Markaz, Islamabad", "area": "G-11", "created_by": salesman_id},
    ]

    print("  Creating customers...")
    customers_result = db.table("customers").insert(customers_data).execute()
    customers = customers_result.data
    print(f"  ✅ Created {len(customers)} customers")

    # === Business Settings ===
    settings_data = [
        {"key": "invoice_counter", "value": {"counter": 0}, "updated_by": admin_id},
        {"key": "business_info", "value": {
            "name": "OneWater Pakistan",
            "address": "Islamabad, Pakistan",
            "phone": "+92-300-0000000",
            "gst_number": "",
        }, "updated_by": admin_id},
        {"key": "credit_policy", "value": {"default_days": 7}, "updated_by": admin_id},
        {"key": "overdue_notification", "value": {"interval_days": 7}, "updated_by": admin_id},
    ]

    print("  Creating business settings...")
    db.table("business_settings").insert(settings_data).execute()
    print("  ✅ Created business settings")

    # === Transactions ===
    today = date.today()
    transactions = [
        # Paid - cash
        {"customer": customers[0], "items": [("bottle_pack_500ml", 2)], "status": "paid", "method": "cash", "days_ago": 0, "user": admin_id},
        {"customer": customers[1], "items": [("bottle_19L_refill", 5)], "status": "paid", "method": "cash", "days_ago": 1, "user": salesman_id},
        {"customer": customers[2], "items": [("bottle_pack_500ml", 3), ("bottle_1_5L", 10)], "status": "paid", "method": "bank_transfer", "days_ago": 2, "user": manager_id},
        # Pending - credit
        {"customer": customers[3], "items": [("bottle_19L_refill", 10)], "status": "pending", "method": "credit", "days_ago": 5, "user": salesman_id},
        {"customer": customers[4], "items": [("bottle_pack_500ml", 5)], "status": "pending", "method": "credit", "days_ago": 10, "user": salesman_id},
        # Partial
        {"customer": customers[0], "items": [("bottle_19L_new", 1), ("bottle_19L_refill", 3)], "status": "partial", "method": "cash", "days_ago": 8, "user": admin_id, "paid_pct": 0.5},
        {"customer": customers[1], "items": [("bottle_1_5L", 20)], "status": "partial", "method": "easypaisa", "days_ago": 12, "user": manager_id, "paid_pct": 0.7},
        # More paid
        {"customer": customers[2], "items": [("bottle_19L_refill", 8)], "status": "paid", "method": "jazzcash", "days_ago": 3, "user": salesman_id},
        {"customer": customers[3], "items": [("bottle_pack_500ml", 1), ("bottle_1_5L", 5)], "status": "paid", "method": "cash", "days_ago": 15, "user": admin_id},
        {"customer": customers[4], "items": [("bottle_19L_new", 2)], "status": "pending", "method": "credit", "days_ago": 20, "user": manager_id},
    ]

    print("  Creating transactions...")
    counter = 0
    for txn in transactions:
        counter += 1
        invoice_number = f"OW-{today.year}-{counter:06d}"
        cust = txn["customer"]
        txn_date = (today - timedelta(days=txn["days_ago"])).isoformat()
        due_date = (today - timedelta(days=txn["days_ago"]) + timedelta(days=7)).isoformat() if txn["status"] != "paid" else None

        # Calculate totals
        subtotal = 0
        items_to_insert = []
        for cat, qty in txn["items"]:
            prod = products[cat]
            line_total = prod["unit_price"] * qty
            if cat == "bottle_19L_new":
                line_total += prod["security_deposit"] * qty
            subtotal += line_total
            items_to_insert.append({
                "product_id": prod["id"],
                "product_name": prod["name"],
                "quantity": qty,
                "unit_price": prod["unit_price"],
                "line_total": line_total,
            })

        total_amount = subtotal
        if txn["status"] == "paid":
            amount_paid = total_amount
        elif txn["status"] == "partial":
            amount_paid = round(total_amount * txn.get("paid_pct", 0.5), 2)
        else:
            amount_paid = 0

        txn_data = {
            "invoice_number": invoice_number,
            "customer_id": cust["id"],
            "customer_name": cust["name"],
            "customer_phone": cust.get("phone"),
            "created_by": txn["user"],
            "transaction_date": txn_date,
            "due_date": due_date,
            "subtotal": subtotal,
            "discount": 0,
            "total_amount": total_amount,
            "amount_paid": amount_paid,
            "payment_status": txn["status"],
            "payment_method": txn["method"],
        }

        txn_result = db.table("transactions").insert(txn_data).execute()
        txn_id = txn_result.data[0]["id"]

        for item in items_to_insert:
            item["transaction_id"] = txn_id
        db.table("transaction_items").insert(items_to_insert).execute()

        # Update customer pending
        if txn["status"] in ("pending", "partial"):
            pending = total_amount - amount_paid
            cur = db.table("customers").select("total_pending").eq("id", cust["id"]).execute()
            cur_pending = float(cur.data[0].get("total_pending", 0)) if cur.data else 0
            db.table("customers").update({"total_pending": cur_pending + pending}).eq("id", cust["id"]).execute()

    # Update invoice counter
    db.table("business_settings").update({"value": {"counter": counter}}).eq("key", "invoice_counter").execute()

    print(f"  ✅ Created {counter} transactions")
    print()
    print("🎉 Seeding complete!")
    print()
    print("Login credentials:")
    print("  Admin:    03001234567 / Admin@123")
    print("  Manager:  03009876543 / Manager@123")
    print("  Salesman: 03005551234 / Sales@123")


if __name__ == "__main__":
    seed()
