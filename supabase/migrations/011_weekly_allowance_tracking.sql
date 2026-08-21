-- ==============================================================================
-- Spendly - Migration 011: Weekly Work Allowance & Budget Tracking
-- Purpose:
-- 1. Create employee_allowance_transactions table for work spending budgets
-- 2. Strict Row Level Security (RLS) policies:
--    - Admins: SELECT, INSERT, UPDATE, DELETE for all records
--    - Employees: SELECT only their own records (auth.uid() = user_id)
-- 3. Automatic updated_at trigger and created_by enforcement
-- 4. Server-side helper function to aggregate weekly work budget summaries
-- ==============================================================================

-- ── 1. Create employee_allowance_transactions Table ───────────────────────────
CREATE TABLE IF NOT EXISTS public.employee_allowance_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    currency TEXT NOT NULL DEFAULT 'EGP' CHECK (currency IN ('EGP', 'USD')),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT NULL,
    created_by UUID NOT NULL REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Indexes for high-performance weekly and user aggregations
CREATE INDEX IF NOT EXISTS idx_allowance_tx_user_curr_date 
    ON public.employee_allowance_transactions(user_id, currency, transaction_date DESC);

CREATE INDEX IF NOT EXISTS idx_allowance_tx_date 
    ON public.employee_allowance_transactions(transaction_date DESC);

CREATE INDEX IF NOT EXISTS idx_allowance_tx_created_by 
    ON public.employee_allowance_transactions(created_by);

-- ── 2. Automatic updated_at Timestamp Trigger ────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_allowance_tx_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_allowance_tx_updated_at ON public.employee_allowance_transactions;
CREATE TRIGGER tr_allowance_tx_updated_at
    BEFORE UPDATE ON public.employee_allowance_transactions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_allowance_tx_updated_at();

-- ── 3. Strict Row Level Security (RLS) ───────────────────────────────────────
ALTER TABLE public.employee_allowance_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins have full access to allowance transactions" ON public.employee_allowance_transactions;
DROP POLICY IF EXISTS "Employees can view their own allowance transactions" ON public.employee_allowance_transactions;
DROP POLICY IF EXISTS "Admins can insert allowance transactions" ON public.employee_allowance_transactions;
DROP POLICY IF EXISTS "Admins can update allowance transactions" ON public.employee_allowance_transactions;
DROP POLICY IF EXISTS "Admins can delete allowance transactions" ON public.employee_allowance_transactions;

-- SELECT: Admins can view all allowance transactions
CREATE POLICY "Admins can view all allowance transactions"
    ON public.employee_allowance_transactions FOR SELECT TO authenticated
    USING (public.is_admin());

-- SELECT: Employees can only view their own allowance transactions
CREATE POLICY "Employees can view their own allowance transactions"
    ON public.employee_allowance_transactions FOR SELECT TO authenticated
    USING (auth.uid() = user_id AND NOT public.is_admin());

-- INSERT: Only Admins can insert allowance transactions, enforcing created_by = auth.uid()
CREATE POLICY "Admins can insert allowance transactions"
    ON public.employee_allowance_transactions FOR INSERT TO authenticated
    WITH CHECK (public.is_admin() AND created_by = auth.uid());

-- UPDATE: Only Admins can update allowance transactions
CREATE POLICY "Admins can update allowance transactions"
    ON public.employee_allowance_transactions FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- DELETE: Only Admins can delete allowance transactions
CREATE POLICY "Admins can delete allowance transactions"
    ON public.employee_allowance_transactions FOR DELETE TO authenticated
    USING (public.is_admin());

-- ── 4. Aggregate Weekly Work Budget Function (Zero N+1 Query Optimization) ───
-- Drop any previous or conflicting parameter orders to prevent overload ambiguities
DROP FUNCTION IF EXISTS public.get_weekly_work_budget_summary(DATE, DATE, UUID);
DROP FUNCTION IF EXISTS public.get_weekly_work_budget_summary(UUID, DATE, DATE);

CREATE OR REPLACE FUNCTION public.get_weekly_work_budget_summary(
    p_start_date DATE,
    p_end_date DATE,
    p_user_id UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_egp_received NUMERIC := 0.0;
    v_egp_spent NUMERIC := 0.0;
    v_usd_received NUMERIC := 0.0;
    v_usd_spent NUMERIC := 0.0;
BEGIN
    -- EGP Received in specified date range
    SELECT COALESCE(SUM(amount), 0.0) INTO v_egp_received
    FROM public.employee_allowance_transactions
    WHERE transaction_date >= p_start_date 
      AND transaction_date <= p_end_date
      AND currency = 'EGP'
      AND (p_user_id IS NULL OR user_id = p_user_id);

    -- EGP Spent in specified date range
    SELECT COALESCE(SUM(amount), 0.0) INTO v_egp_spent
    FROM public.expenses
    WHERE expense_date >= p_start_date 
      AND expense_date <= p_end_date
      AND currency = 'EGP'
      AND (p_user_id IS NULL OR user_id = p_user_id);

    -- USD Received in specified date range
    SELECT COALESCE(SUM(amount), 0.0) INTO v_usd_received
    FROM public.employee_allowance_transactions
    WHERE transaction_date >= p_start_date 
      AND transaction_date <= p_end_date
      AND currency = 'USD'
      AND (p_user_id IS NULL OR user_id = p_user_id);

    -- USD Spent in specified date range
    SELECT COALESCE(SUM(amount), 0.0) INTO v_usd_spent
    FROM public.expenses
    WHERE expense_date >= p_start_date 
      AND expense_date <= p_end_date
      AND currency = 'USD'
      AND (p_user_id IS NULL OR user_id = p_user_id);

    RETURN json_build_object(
        'start_date', p_start_date,
        'end_date', p_end_date,
        'user_id', p_user_id,
        'egp_received', v_egp_received,
        'egp_spent', v_egp_spent,
        'egp_remaining', (v_egp_received - v_egp_spent),
        'usd_received', v_usd_received,
        'usd_spent', v_usd_spent,
        'usd_remaining', (v_usd_received - v_usd_spent)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_weekly_work_budget_summary(DATE, DATE, UUID) TO authenticated;

-- ── 5. Reload PostgREST Schema Cache ─────────────────────────────────────────
NOTIFY pgrst, 'reload schema';
