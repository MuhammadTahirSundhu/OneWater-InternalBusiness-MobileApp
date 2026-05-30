-- ============================================================
-- OneWater Pakistan — Complete Database Schema (v2)
-- Run this once in Supabase SQL Editor on a fresh project
-- ============================================================

-- ==========================================
-- Users table
-- ==========================================
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name       TEXT NOT NULL,
    phone           TEXT UNIQUE NOT NULL,
    email           TEXT UNIQUE,
    role            TEXT NOT NULL CHECK (role IN ('admin', 'manager', 'salesman')),
    password_hash   TEXT NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE,
    avatar_url      TEXT,
    onboarding_done BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- Customers table
-- ==========================================
CREATE TABLE IF NOT EXISTS customers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    phone           TEXT,
    address         TEXT,
    area            TEXT,
    notes           TEXT,
    total_pending   NUMERIC(10,2) DEFAULT 0,
    loyalty_points  INTEGER DEFAULT 0,
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- Products table
-- ==========================================
CREATE TABLE IF NOT EXISTS products (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name             TEXT NOT NULL,
    sku              TEXT UNIQUE NOT NULL,
    category         TEXT NOT NULL CHECK (category IN (
                         'bottle_pack_500ml',
                         'bottle_1_5L',
                         'bottle_19L_new',
                         'bottle_19L_refill',
                         'refill_filter_water',
                         'mineral_water'
                     )),
    unit_price       NUMERIC(10,2) NOT NULL,
    security_deposit NUMERIC(10,2) DEFAULT 0,
    is_active        BOOLEAN DEFAULT TRUE,
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- Transactions table
-- ==========================================
CREATE TABLE IF NOT EXISTS transactions (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number   TEXT UNIQUE NOT NULL,
    customer_id      UUID REFERENCES customers(id) ON DELETE RESTRICT,
    customer_name    TEXT NOT NULL,
    customer_phone   TEXT,
    created_by       UUID REFERENCES users(id),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date         DATE,
    subtotal         NUMERIC(10,2) NOT NULL,
    discount         NUMERIC(10,2) DEFAULT 0,
    discount_type    TEXT DEFAULT 'flat' CHECK (discount_type IN ('flat', 'percent')),
    total_amount     NUMERIC(10,2) NOT NULL,
    amount_paid      NUMERIC(10,2) DEFAULT 0,
    payment_status   TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('paid', 'pending', 'partial', 'voided')),
    payment_method   TEXT CHECK (payment_method IN ('cash', 'bank_transfer', 'easypaisa', 'jazzcash', 'credit')),
    notes            TEXT,
    invoice_pdf_url  TEXT,
    branch_id        UUID,
    delivery_status  TEXT,
    delivery_address TEXT,
    tax_rate         NUMERIC(5,2),
    tax_amount       NUMERIC(10,2),
    voided_by        UUID REFERENCES users(id),
    voided_at        TIMESTAMPTZ,
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- Transaction Items table
-- ==========================================
CREATE TABLE IF NOT EXISTS transaction_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id  UUID REFERENCES transactions(id) ON DELETE CASCADE,
    product_id      UUID REFERENCES products(id) ON DELETE RESTRICT,
    product_name    TEXT NOT NULL,
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10,2) NOT NULL,
    line_total      NUMERIC(10,2) NOT NULL
);

-- ==========================================
-- Payment Collections table
-- ==========================================
CREATE TABLE IF NOT EXISTS payment_collections (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id  UUID REFERENCES transactions(id) ON DELETE RESTRICT,
    collected_by    UUID REFERENCES users(id),
    amount          NUMERIC(10,2) NOT NULL,
    collected_at    TIMESTAMPTZ DEFAULT NOW(),
    payment_method  TEXT CHECK (payment_method IN ('cash', 'bank_transfer', 'easypaisa', 'jazzcash')),
    notes           TEXT
);

-- ==========================================
-- Expenses table
-- ==========================================
CREATE TABLE IF NOT EXISTS expenses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    description     TEXT NOT NULL,
    amount          NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    category        TEXT NOT NULL DEFAULT 'other' CHECK (category IN (
                        'fuel', 'salary', 'utilities', 'office', 'maintenance', 'other'
                    )),
    expense_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    notes           TEXT,
    recorded_by     UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- Amount In table (general cash inflows)
-- ==========================================
CREATE TABLE IF NOT EXISTS amount_in (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    description     TEXT NOT NULL,
    amount          NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    notes           TEXT,
    recorded_by     UUID REFERENCES users(id),
    recorded_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- Audit Logs table
-- ==========================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id),
    user_name       TEXT NOT NULL,
    action          TEXT NOT NULL,
    entity_type     TEXT NOT NULL,
    entity_id       UUID,
    old_value       JSONB,
    new_value       JSONB,
    ip_address      TEXT,
    device_info     TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- Notifications table
-- ==========================================
CREATE TABLE IF NOT EXISTS notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type            TEXT NOT NULL,
    title           TEXT NOT NULL,
    body            TEXT NOT NULL,
    target_roles    TEXT[] DEFAULT '{}',
    is_read         BOOLEAN DEFAULT FALSE,
    related_data    JSONB,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- Business Settings table
-- ==========================================
CREATE TABLE IF NOT EXISTS business_settings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key             TEXT UNIQUE NOT NULL,
    value           JSONB NOT NULL,
    updated_by      UUID REFERENCES users(id),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- Indexes for performance
-- ==========================================
CREATE INDEX IF NOT EXISTS idx_transactions_customer   ON transactions(customer_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date       ON transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_status     ON transactions(payment_status);
CREATE INDEX IF NOT EXISTS idx_transactions_created_by ON transactions(created_by);
CREATE INDEX IF NOT EXISTS idx_transaction_items_txn   ON transaction_items(transaction_id);
CREATE INDEX IF NOT EXISTS idx_payment_collections_txn ON payment_collections(transaction_id);
CREATE INDEX IF NOT EXISTS idx_customers_pending       ON customers(total_pending) WHERE total_pending > 0;
CREATE INDEX IF NOT EXISTS idx_audit_logs_user         ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action       ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created      ON audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_roles     ON notifications USING GIN(target_roles);
CREATE INDEX IF NOT EXISTS idx_expenses_date           ON expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_recorded_by    ON expenses(recorded_by);
CREATE INDEX IF NOT EXISTS idx_amount_in_date          ON amount_in(recorded_date);

-- ==========================================
-- Row Level Security (RLS)
-- ==========================================
ALTER TABLE users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers          ENABLE ROW LEVEL SECURITY;
ALTER TABLE products           ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_items  ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses           ENABLE ROW LEVEL SECURITY;
ALTER TABLE amount_in          ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs         ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications      ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_settings  ENABLE ROW LEVEL SECURITY;

-- Service role bypass (FastAPI uses service key — full access)
CREATE POLICY "Service role full access" ON users              FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON customers          FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON products           FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON transactions       FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON transaction_items  FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON payment_collections FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON expenses           FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON amount_in          FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON audit_logs         FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON notifications      FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON business_settings  FOR ALL USING (true) WITH CHECK (true);

-- ==========================================
-- Storage bucket for invoices
-- Run separately or via Supabase dashboard:
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('invoices', 'invoices', false)
-- ON CONFLICT (id) DO NOTHING;
-- ==========================================
