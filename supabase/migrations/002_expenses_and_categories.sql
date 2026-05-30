-- OneWater Pakistan — Migration 002
-- Adds expenses table, amount_in table, and new product categories

-- ==========================================
-- Alter products category CHECK constraint
-- ==========================================
ALTER TABLE products DROP CONSTRAINT IF EXISTS products_category_check;
ALTER TABLE products ADD CONSTRAINT products_category_check
    CHECK (category IN (
        'bottle_pack_500ml',
        'bottle_1_5L',
        'bottle_19L_new',
        'bottle_19L_refill',
        'refill_filter_water',
        'mineral_water'
    ));

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
-- Amount In table (general cash inflows, not tied to a transaction)
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
-- RLS
-- ==========================================
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE amount_in ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access" ON expenses FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON amount_in FOR ALL USING (true) WITH CHECK (true);

-- ==========================================
-- Indexes
-- ==========================================
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_recorded_by ON expenses(recorded_by);
CREATE INDEX IF NOT EXISTS idx_amount_in_date ON amount_in(recorded_date);
