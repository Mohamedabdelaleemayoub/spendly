-- ============================================================================
-- Migration 007: Employee Allowance & Spending Balance System
-- ============================================================================

-- 1. Create employee_balance_transactions table for auditable allowance history
CREATE TABLE IF NOT EXISTS public.employee_balance_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    type TEXT NOT NULL CHECK (type IN ('credit', 'adjustment_add', 'adjustment_sub')),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Index for fast user balance transaction queries
CREATE INDEX IF NOT EXISTS idx_balance_tx_user_id ON public.employee_balance_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_balance_tx_date ON public.employee_balance_transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_balance_tx_created_by ON public.employee_balance_transactions(created_by);

-- 2. Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.set_balance_tx_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_balance_tx_updated_at ON public.employee_balance_transactions;
CREATE TRIGGER tr_balance_tx_updated_at
BEFORE UPDATE ON public.employee_balance_transactions
FOR EACH ROW
EXECUTE FUNCTION public.set_balance_tx_updated_at();

-- 3. Calculate Available Balance for an Employee
CREATE OR REPLACE FUNCTION public.get_employee_available_balance(p_user_id UUID)
RETURNS NUMERIC AS $$
DECLARE
    v_total_received NUMERIC := 0.0;
    v_total_adjust_sub NUMERIC := 0.0;
    v_total_spent NUMERIC := 0.0;
BEGIN
    -- Sum all credits & positive adjustments
    SELECT COALESCE(SUM(amount), 0.0)
    INTO v_total_received
    FROM public.employee_balance_transactions
    WHERE user_id = p_user_id AND type IN ('credit', 'adjustment_add');

    -- Sum negative adjustments
    SELECT COALESCE(SUM(amount), 0.0)
    INTO v_total_adjust_sub
    FROM public.employee_balance_transactions
    WHERE user_id = p_user_id AND type = 'adjustment_sub';

    -- Sum all expenses
    SELECT COALESCE(SUM(amount), 0.0)
    INTO v_total_spent
    FROM public.expenses
    WHERE user_id = p_user_id;

    RETURN (v_total_received - v_total_adjust_sub - v_total_spent);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- 4. Get Employee Balance Summary (Received, Spent, Available)
CREATE OR REPLACE FUNCTION public.get_employee_balance_summary(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_total_received NUMERIC := 0.0;
    v_total_adjust_sub NUMERIC := 0.0;
    v_total_spent NUMERIC := 0.0;
    v_available NUMERIC := 0.0;
BEGIN
    SELECT COALESCE(SUM(amount), 0.0)
    INTO v_total_received
    FROM public.employee_balance_transactions
    WHERE user_id = p_user_id AND type IN ('credit', 'adjustment_add');

    SELECT COALESCE(SUM(amount), 0.0)
    INTO v_total_adjust_sub
    FROM public.employee_balance_transactions
    WHERE user_id = p_user_id AND type = 'adjustment_sub';

    SELECT COALESCE(SUM(amount), 0.0)
    INTO v_total_spent
    FROM public.expenses
    WHERE user_id = p_user_id;

    v_available := (v_total_received - v_total_adjust_sub - v_total_spent);

    RETURN json_build_object(
        'user_id', p_user_id,
        'total_received', v_total_received,
        'total_adjust_sub', v_total_adjust_sub,
        'total_spent', v_total_spent,
        'available_balance', v_available
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- 5. Get All Employee Balances (For Admin Employee Balances View - avoids N+1 queries)
CREATE OR REPLACE FUNCTION public.get_all_employee_balances()
RETURNS TABLE (
    user_id UUID,
    name TEXT,
    email TEXT,
    role TEXT,
    status TEXT,
    avatar_url TEXT,
    total_received NUMERIC,
    total_spent NUMERIC,
    available_balance NUMERIC,
    last_allowance_date DATE
) AS $$
BEGIN
    RETURN QUERY
    WITH credit_totals AS (
        SELECT
            tx.user_id AS uid,
            COALESCE(SUM(CASE WHEN tx.type IN ('credit', 'adjustment_add') THEN tx.amount ELSE -tx.amount END), 0.0) AS net_credit,
            COALESCE(SUM(CASE WHEN tx.type IN ('credit', 'adjustment_add') THEN tx.amount ELSE 0.0 END), 0.0) AS total_rec,
            MAX(tx.transaction_date) AS last_date
        FROM public.employee_balance_transactions tx
        GROUP BY tx.user_id
    ),
    expense_totals AS (
        SELECT
            e.user_id AS uid,
            COALESCE(SUM(e.amount), 0.0) AS total_sp
        FROM public.expenses e
        GROUP BY e.user_id
    )
    SELECT
        p.id AS user_id,
        COALESCE(p.full_name, 'مستخدم') AS name,
        p.email,
        p.role,
        p.status,
        p.avatar_url,
        COALESCE(ct.total_rec, 0.0) AS total_received,
        COALESCE(et.total_sp, 0.0) AS total_spent,
        (COALESCE(ct.net_credit, 0.0) - COALESCE(et.total_sp, 0.0)) AS available_balance,
        ct.last_date AS last_allowance_date
    FROM public.profiles p
    LEFT JOIN credit_totals ct ON ct.uid = p.id
    LEFT JOIN expense_totals et ON et.uid = p.id
    ORDER BY COALESCE(p.full_name, 'مستخدم') ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- 6. Server-Side Atomic Balance Enforcement Trigger on public.expenses
CREATE OR REPLACE FUNCTION public.enforce_expense_balance_limit()
RETURNS TRIGGER AS $$
DECLARE
    v_user_role TEXT;
    v_available NUMERIC;
BEGIN
    -- Acquire transaction advisory lock for this user to serialize concurrent expense operations
    PERFORM pg_advisory_xact_lock(hashtext(NEW.user_id::text));

    -- Check user role
    SELECT role INTO v_user_role FROM public.profiles WHERE id = NEW.user_id;

    -- Enforce for employees and regular users (admins exempt)
    IF v_user_role = 'employee' OR v_user_role IS NULL THEN
        IF TG_OP = 'INSERT' THEN
            v_available := public.get_employee_available_balance(NEW.user_id);
            IF NEW.amount > v_available THEN
                RAISE EXCEPTION 'INSUFFICIENT_BALANCE: Expense amount (%) exceeds available balance (%)',
                    NEW.amount, v_available;
            END IF;
        ELSIF TG_OP = 'UPDATE' THEN
            -- If user is changing the expense owner, check target user
            IF NEW.user_id <> OLD.user_id THEN
                PERFORM pg_advisory_xact_lock(hashtext(OLD.user_id::text));
                v_available := public.get_employee_available_balance(NEW.user_id);
                IF NEW.amount > v_available THEN
                    RAISE EXCEPTION 'INSUFFICIENT_BALANCE: Expense amount (%) exceeds available balance (%)',
                        NEW.amount, v_available;
                END IF;
            -- If amount is increasing, ensure available balance covers the delta
            ELSIF NEW.amount > OLD.amount THEN
                v_available := public.get_employee_available_balance(NEW.user_id);
                IF (NEW.amount - OLD.amount) > v_available THEN
                    RAISE EXCEPTION 'INSUFFICIENT_BALANCE: Additional expense amount (%) exceeds available balance (%)',
                        (NEW.amount - OLD.amount), v_available;
                END IF;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS tr_enforce_expense_balance ON public.expenses;
CREATE TRIGGER tr_enforce_expense_balance
BEFORE INSERT OR UPDATE ON public.expenses
FOR EACH ROW
EXECUTE FUNCTION public.enforce_expense_balance_limit();

-- 7. Enable RLS and Configure Security Policies for employee_balance_transactions
ALTER TABLE public.employee_balance_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins and owners can view balance transactions" ON public.employee_balance_transactions;
CREATE POLICY "Admins and owners can view balance transactions"
ON public.employee_balance_transactions
FOR SELECT
TO authenticated
USING (
    public.is_admin() OR auth.uid() = user_id
);

DROP POLICY IF EXISTS "Only admins can insert balance transactions" ON public.employee_balance_transactions;
CREATE POLICY "Only admins can insert balance transactions"
ON public.employee_balance_transactions
FOR INSERT
TO authenticated
WITH CHECK (
    public.is_admin()
);

DROP POLICY IF EXISTS "Only admins can update balance transactions" ON public.employee_balance_transactions;
CREATE POLICY "Only admins can update balance transactions"
ON public.employee_balance_transactions
FOR UPDATE
TO authenticated
USING (
    public.is_admin()
)
WITH CHECK (
    public.is_admin()
);

DROP POLICY IF EXISTS "Only admins can delete balance transactions" ON public.employee_balance_transactions;
CREATE POLICY "Only admins can delete balance transactions"
ON public.employee_balance_transactions
FOR DELETE
TO authenticated
USING (
    public.is_admin()
);

-- 8. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
