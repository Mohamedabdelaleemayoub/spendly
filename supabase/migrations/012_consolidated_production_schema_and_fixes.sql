-- ==============================================================================
-- Spendly - Migration 012: Consolidated Production Schema, Columns & RPC Fixes
-- Purpose: 
--   1. Fix missing columns across profiles, expenses, and balance tables.
--   2. Ensure all tables (employee_balance_transactions, employee_salary_advances, 
--      employee_allowance_transactions, app_settings, admin_notifications) exist.
--   3. Deploy robust, multi-currency server RPCs for employee balances & weekly budgets.
--   4. Refresh PostgREST schema cache.
-- ==============================================================================

-- ── 1. Profiles Table Updates ─────────────────────────────────────────────────
DO $$
BEGIN
    -- Ensure full_name column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'full_name'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN full_name TEXT NOT NULL DEFAULT 'مستخدم';
    END IF;

    -- Ensure status column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'status'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN status TEXT NOT NULL DEFAULT 'active';
    END IF;

    -- Ensure salary columns exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'salary_amount'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN salary_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.0;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'salary_currency'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN salary_currency TEXT NOT NULL DEFAULT 'EGP';
    END IF;
END $$;

-- Update constraints on profiles safely
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_status_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_status_check CHECK (status IN ('active', 'inactive', 'pending', 'rejected'));

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_salary_amount_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_salary_amount_check CHECK (salary_amount >= 0);

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_salary_currency_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_salary_currency_check CHECK (salary_currency IN ('EGP', 'USD'));

CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(status);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- ── 2. Expenses Table Updates (Multi-Currency & Travel Tracking) ─────────────
DO $$
BEGIN
    -- Ensure currency column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'expenses' AND column_name = 'currency'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN currency TEXT NOT NULL DEFAULT 'EGP';
    END IF;

    -- Ensure trip location columns exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'expenses' AND column_name = 'trip_location_type'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN trip_location_type TEXT NOT NULL DEFAULT 'cairo';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'expenses' AND column_name = 'governorate'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN governorate TEXT NOT NULL DEFAULT 'cairo';
    END IF;
END $$;

-- Add constraints on expenses
ALTER TABLE public.expenses DROP CONSTRAINT IF EXISTS expenses_currency_check;
ALTER TABLE public.expenses ADD CONSTRAINT expenses_currency_check CHECK (currency IN ('EGP', 'USD'));

ALTER TABLE public.expenses DROP CONSTRAINT IF EXISTS expenses_trip_location_type_check;
ALTER TABLE public.expenses ADD CONSTRAINT expenses_trip_location_type_check CHECK (trip_location_type IN ('cairo', 'outside_cairo'));

CREATE INDEX IF NOT EXISTS idx_expenses_currency ON public.expenses(currency);
CREATE INDEX IF NOT EXISTS idx_expenses_trip_location ON public.expenses(trip_location_type, governorate);
CREATE INDEX IF NOT EXISTS idx_expenses_user_date_curr ON public.expenses(user_id, expense_date DESC, currency);

-- ── 3. Employee Balance Transactions Table ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.employee_balance_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    currency TEXT NOT NULL DEFAULT 'EGP' CHECK (currency IN ('EGP', 'USD')),
    type TEXT NOT NULL CHECK (type IN ('credit', 'adjustment_add', 'adjustment_sub')),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'employee_balance_transactions' AND column_name = 'currency'
    ) THEN
        ALTER TABLE public.employee_balance_transactions ADD COLUMN currency TEXT NOT NULL DEFAULT 'EGP' CHECK (currency IN ('EGP', 'USD'));
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_ebt_user_id ON public.employee_balance_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_ebt_user_curr ON public.employee_balance_transactions(user_id, currency);

ALTER TABLE public.employee_balance_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins have full access to employee_balance_transactions" ON public.employee_balance_transactions;
DROP POLICY IF EXISTS "Employees can view their own balance transactions" ON public.employee_balance_transactions;

CREATE POLICY "Admins have full access to employee_balance_transactions"
    ON public.employee_balance_transactions FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

CREATE POLICY "Employees can view their own balance transactions"
    ON public.employee_balance_transactions FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

-- ── 4. Salary Advances Table ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.employee_salary_advances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    currency TEXT NOT NULL DEFAULT 'EGP' CHECK (currency IN ('EGP', 'USD')),
    advance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_esa_user_id ON public.employee_salary_advances(user_id);
CREATE INDEX IF NOT EXISTS idx_esa_advance_date ON public.employee_salary_advances(advance_date DESC);

ALTER TABLE public.employee_salary_advances ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins have full access to employee_salary_advances" ON public.employee_salary_advances;
CREATE POLICY "Admins have full access to employee_salary_advances"
    ON public.employee_salary_advances FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ── 5. Weekly Work Allowance Transactions Table ─────────────────────────────
CREATE TABLE IF NOT EXISTS public.employee_allowance_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    currency TEXT NOT NULL DEFAULT 'EGP' CHECK (currency IN ('EGP', 'USD')),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_eat_user_date ON public.employee_allowance_transactions(user_id, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_eat_user_curr ON public.employee_allowance_transactions(user_id, currency);

ALTER TABLE public.employee_allowance_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins have full access to employee_allowance_transactions" ON public.employee_allowance_transactions;
DROP POLICY IF EXISTS "Employees can view their own allowance transactions" ON public.employee_allowance_transactions;

CREATE POLICY "Admins have full access to employee_allowance_transactions"
    ON public.employee_allowance_transactions FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

CREATE POLICY "Employees can view their own allowance transactions"
    ON public.employee_allowance_transactions FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

-- ── 6. App Settings Table (Approval & Travel Bonus) ─────────────────────────
CREATE TABLE IF NOT EXISTS public.app_settings (
    id TEXT PRIMARY KEY DEFAULT 'default',
    require_admin_approval BOOLEAN NOT NULL DEFAULT true,
    travel_bonus_enabled BOOLEAN NOT NULL DEFAULT false,
    travel_bonus_amount NUMERIC(12, 2) NOT NULL DEFAULT 150.00 CHECK (travel_bonus_amount >= 0),
    travel_bonus_currency TEXT NOT NULL DEFAULT 'EGP' CHECK (travel_bonus_currency IN ('EGP', 'USD')),
    updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

INSERT INTO public.app_settings (id, require_admin_approval, travel_bonus_enabled, travel_bonus_amount, travel_bonus_currency)
VALUES ('default', true, false, 150.00, 'EGP')
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone authenticated can view app_settings" ON public.app_settings;
DROP POLICY IF EXISTS "Only Admins can update app_settings" ON public.app_settings;

CREATE POLICY "Anyone authenticated can view app_settings"
    ON public.app_settings FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "Only Admins can update app_settings"
    ON public.app_settings FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ── 7. Admin Notifications Table ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'new_user_registration',
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_admin_notifications_unread ON public.admin_notifications(is_read, created_at DESC);

ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Only admins can access admin_notifications" ON public.admin_notifications;
CREATE POLICY "Only admins can access admin_notifications"
    ON public.admin_notifications FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ── 8. RPC: get_all_employee_balances() ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_all_employee_balances()
RETURNS TABLE (
    user_id UUID,
    name TEXT,
    email TEXT,
    role TEXT,
    status TEXT,
    avatar_url TEXT,
    total_received_egp NUMERIC,
    total_spent_egp NUMERIC,
    available_balance_egp NUMERIC,
    total_received_usd NUMERIC,
    total_spent_usd NUMERIC,
    available_balance_usd NUMERIC
) AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied. Admins only.';
    END IF;

    RETURN QUERY
    SELECT 
        p.id AS user_id,
        p.full_name AS name,
        p.email,
        p.role,
        COALESCE(p.status, 'active') AS status,
        p.avatar_url,
        
        -- EGP Calculations
        COALESCE(SUM(CASE WHEN bt.currency = 'EGP' AND bt.type IN ('credit', 'adjustment_add') THEN bt.amount ELSE 0 END), 0)::NUMERIC AS total_received_egp,
        COALESCE(e_egp.total_spent, 0)::NUMERIC AS total_spent_egp,
        (
            COALESCE(SUM(CASE WHEN bt.currency = 'EGP' AND bt.type IN ('credit', 'adjustment_add') THEN bt.amount ELSE 0 END), 0) -
            COALESCE(SUM(CASE WHEN bt.currency = 'EGP' AND bt.type = 'adjustment_sub' THEN bt.amount ELSE 0 END), 0) -
            COALESCE(e_egp.total_spent, 0)
        )::NUMERIC AS available_balance_egp,

        -- USD Calculations
        COALESCE(SUM(CASE WHEN bt.currency = 'USD' AND bt.type IN ('credit', 'adjustment_add') THEN bt.amount ELSE 0 END), 0)::NUMERIC AS total_received_usd,
        COALESCE(e_usd.total_spent, 0)::NUMERIC AS total_spent_usd,
        (
            COALESCE(SUM(CASE WHEN bt.currency = 'USD' AND bt.type IN ('credit', 'adjustment_add') THEN bt.amount ELSE 0 END), 0) -
            COALESCE(SUM(CASE WHEN bt.currency = 'USD' AND bt.type = 'adjustment_sub' THEN bt.amount ELSE 0 END), 0) -
            COALESCE(e_usd.total_spent, 0)
        )::NUMERIC AS available_balance_usd

    FROM public.profiles p
    LEFT JOIN public.employee_balance_transactions bt ON p.id = bt.user_id
    LEFT JOIN (
        SELECT exp.user_id, SUM(exp.amount) AS total_spent
        FROM public.expenses exp
        WHERE COALESCE(exp.currency, 'EGP') = 'EGP'
        GROUP BY exp.user_id
    ) e_egp ON p.id = e_egp.user_id
    LEFT JOIN (
        SELECT exp.user_id, SUM(exp.amount) AS total_spent
        FROM public.expenses exp
        WHERE exp.currency = 'USD'
        GROUP BY exp.user_id
    ) e_usd ON p.id = e_usd.user_id
    GROUP BY p.id, p.full_name, p.email, p.role, p.status, p.avatar_url, e_egp.total_spent, e_usd.total_spent
    ORDER BY p.full_name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- ── 9. RPC: get_employee_balance_summary() ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_employee_balance_summary(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_egp_received NUMERIC := 0;
    v_egp_adjust_sub NUMERIC := 0;
    v_egp_spent NUMERIC := 0;
    v_usd_received NUMERIC := 0;
    v_usd_adjust_sub NUMERIC := 0;
    v_usd_spent NUMERIC := 0;
    v_result JSON;
BEGIN
    IF auth.uid() <> p_user_id AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied. You can only view your own balance summary.';
    END IF;

    -- EGP Received & Adjust Sub
    SELECT 
        COALESCE(SUM(CASE WHEN type IN ('credit', 'adjustment_add') THEN amount ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN type = 'adjustment_sub' THEN amount ELSE 0 END), 0)
    INTO v_egp_received, v_egp_adjust_sub
    FROM public.employee_balance_transactions
    WHERE user_id = p_user_id AND currency = 'EGP';

    -- EGP Spent
    SELECT COALESCE(SUM(amount), 0)
    INTO v_egp_spent
    FROM public.expenses
    WHERE user_id = p_user_id AND COALESCE(currency, 'EGP') = 'EGP';

    -- USD Received & Adjust Sub
    SELECT 
        COALESCE(SUM(CASE WHEN type IN ('credit', 'adjustment_add') THEN amount ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN type = 'adjustment_sub' THEN amount ELSE 0 END), 0)
    INTO v_usd_received, v_usd_adjust_sub
    FROM public.employee_balance_transactions
    WHERE user_id = p_user_id AND currency = 'USD';

    -- USD Spent
    SELECT COALESCE(SUM(amount), 0)
    INTO v_usd_spent
    FROM public.expenses
    WHERE user_id = p_user_id AND currency = 'USD';

    SELECT json_build_object(
        'user_id', p_user_id,
        'total_received_egp', v_egp_received,
        'total_spent_egp', v_egp_spent,
        'available_balance_egp', (v_egp_received - v_egp_adjust_sub - v_egp_spent),
        'total_received_usd', v_usd_received,
        'total_spent_usd', v_usd_spent,
        'available_balance_usd', (v_usd_received - v_usd_adjust_sub - v_usd_spent)
    ) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- ── 10. RPC: get_weekly_work_budget_summary() ──────────────────────────────
CREATE OR REPLACE FUNCTION public.get_weekly_work_budget_summary(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS JSON AS $$
DECLARE
    v_egp_received NUMERIC := 0;
    v_egp_spent NUMERIC := 0;
    v_usd_received NUMERIC := 0;
    v_usd_spent NUMERIC := 0;
    v_result JSON;
BEGIN
    IF auth.uid() <> p_user_id AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied. You can only view your own weekly budget.';
    END IF;

    -- 1. EGP Received
    SELECT COALESCE(SUM(amount), 0)
    INTO v_egp_received
    FROM public.employee_allowance_transactions
    WHERE user_id = p_user_id
      AND currency = 'EGP'
      AND transaction_date >= p_start_date
      AND transaction_date <= p_end_date;

    -- 2. EGP Spent
    SELECT COALESCE(SUM(amount), 0)
    INTO v_egp_spent
    FROM public.expenses
    WHERE user_id = p_user_id
      AND COALESCE(currency, 'EGP') = 'EGP'
      AND expense_date >= p_start_date
      AND expense_date <= p_end_date;

    -- 3. USD Received
    SELECT COALESCE(SUM(amount), 0)
    INTO v_usd_received
    FROM public.employee_allowance_transactions
    WHERE user_id = p_user_id
      AND currency = 'USD'
      AND transaction_date >= p_start_date
      AND transaction_date <= p_end_date;

    -- 4. USD Spent
    SELECT COALESCE(SUM(amount), 0)
    INTO v_usd_spent
    FROM public.expenses
    WHERE user_id = p_user_id
      AND currency = 'USD'
      AND expense_date >= p_start_date
      AND expense_date <= p_end_date;

    SELECT json_build_object(
        'user_id', p_user_id,
        'start_date', p_start_date,
        'end_date', p_end_date,
        'received_egp', v_egp_received,
        'spent_egp', v_egp_spent,
        'remaining_egp', (v_egp_received - v_egp_spent),
        'received_usd', v_usd_received,
        'spent_usd', v_usd_spent,
        'remaining_usd', (v_usd_received - v_usd_spent)
    ) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- ── 11. Trigger: Enforce Employee Expense Balance ────────────────────────────
CREATE OR REPLACE FUNCTION public.enforce_employee_expense_balance()
RETURNS TRIGGER AS $$
DECLARE
    v_user_role TEXT;
    v_currency TEXT;
    v_available_balance NUMERIC;
    v_expense_amount NUMERIC;
    v_difference NUMERIC;
BEGIN
    SELECT role INTO v_user_role
    FROM public.profiles
    WHERE id = NEW.user_id;

    IF v_user_role = 'admin' THEN
        RETURN NEW;
    END IF;

    v_currency := COALESCE(NEW.currency, 'EGP');
    v_expense_amount := NEW.amount;

    IF TG_OP = 'UPDATE' THEN
        IF OLD.user_id = NEW.user_id AND COALESCE(OLD.currency, 'EGP') = v_currency THEN
            v_difference := v_expense_amount - OLD.amount;
            IF v_difference <= 0 THEN
                RETURN NEW;
            END IF;
            v_expense_amount := v_difference;
        END IF;
    END IF;

    SELECT 
        (
            COALESCE((
                SELECT SUM(amount)
                FROM public.employee_balance_transactions
                WHERE user_id = NEW.user_id
                  AND currency = v_currency
                  AND type IN ('credit', 'adjustment_add')
            ), 0)
            -
            COALESCE((
                SELECT SUM(amount)
                FROM public.employee_balance_transactions
                WHERE user_id = NEW.user_id
                  AND currency = v_currency
                  AND type = 'adjustment_sub'
            ), 0)
            -
            COALESCE((
                SELECT SUM(amount)
                FROM public.expenses
                WHERE user_id = NEW.user_id
                  AND COALESCE(currency, 'EGP') = v_currency
                  AND (TG_OP = 'INSERT' OR id <> NEW.id)
            ), 0)
        )
    INTO v_available_balance;

    IF v_available_balance < v_expense_amount THEN
        RAISE EXCEPTION 'الرصيد المتاح غير كافٍ لتسجيل هذا المصروف. الرصيد المتاح: % % والمطلوب: % %',
            ROUND(v_available_balance, 2), v_currency, ROUND(v_expense_amount, 2), v_currency;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_enforce_employee_expense_balance ON public.expenses;
CREATE TRIGGER on_enforce_employee_expense_balance
    BEFORE INSERT OR UPDATE OF amount, currency, user_id ON public.expenses
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_employee_expense_balance();

-- ── 12. Reload PostgREST Schema Cache ────────────────────────────────────────
NOTIFY pgrst, 'reload schema';
