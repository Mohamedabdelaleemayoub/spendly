-- ============================================================================
-- Migration 008: Multi-Currency Support (EGP & USD)
-- Spendly Egyptian Office: Daily expenses (EGP) & Student/Bank payments (USD)
-- ============================================================================

-- 1. Add currency column to public.expenses if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'expenses' AND column_name = 'currency'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN currency TEXT NOT NULL DEFAULT 'EGP';
    END IF;
END $$;

ALTER TABLE public.expenses DROP CONSTRAINT IF EXISTS expenses_currency_check;
ALTER TABLE public.expenses ADD CONSTRAINT expenses_currency_check CHECK (currency IN ('EGP', 'USD'));

CREATE INDEX IF NOT EXISTS idx_expenses_user_currency ON public.expenses(user_id, currency);

-- 2. Add currency column to public.employee_balance_transactions if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'employee_balance_transactions' AND column_name = 'currency'
    ) THEN
        ALTER TABLE public.employee_balance_transactions ADD COLUMN currency TEXT NOT NULL DEFAULT 'EGP';
    END IF;
END $$;

ALTER TABLE public.employee_balance_transactions DROP CONSTRAINT IF EXISTS employee_balance_transactions_currency_check;
ALTER TABLE public.employee_balance_transactions ADD CONSTRAINT employee_balance_transactions_currency_check CHECK (currency IN ('EGP', 'USD'));

CREATE INDEX IF NOT EXISTS idx_balance_tx_user_currency ON public.employee_balance_transactions(user_id, currency);

-- 3. Calculate Available Balance for an Employee by Currency
-- Drop previous signatures to prevent ambiguous function overloads and signature conflicts
DROP FUNCTION IF EXISTS public.get_employee_available_balance(UUID);
DROP FUNCTION IF EXISTS public.get_employee_available_balance(UUID, TEXT);

CREATE OR REPLACE FUNCTION public.get_employee_available_balance(p_user_id UUID, p_currency TEXT DEFAULT 'EGP')
RETURNS NUMERIC AS $$
DECLARE
    v_total_received NUMERIC := 0.0;
    v_total_adjust_sub NUMERIC := 0.0;
    v_total_spent NUMERIC := 0.0;
    v_curr TEXT := COALESCE(p_currency, 'EGP');
BEGIN
    -- Sum credits & positive adjustments for specific currency
    SELECT COALESCE(SUM(amount), 0.0)
    INTO v_total_received
    FROM public.employee_balance_transactions
    WHERE user_id = p_user_id AND currency = v_curr AND type IN ('credit', 'adjustment_add');

    -- Sum negative adjustments for specific currency
    SELECT COALESCE(SUM(amount), 0.0)
    INTO v_total_adjust_sub
    FROM public.employee_balance_transactions
    WHERE user_id = p_user_id AND currency = v_curr AND type = 'adjustment_sub';

    -- Sum expenses for specific currency
    SELECT COALESCE(SUM(amount), 0.0)
    INTO v_total_spent
    FROM public.expenses
    WHERE user_id = p_user_id AND currency = v_curr;

    RETURN (v_total_received - v_total_adjust_sub - v_total_spent);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- 4. Get Employee Balance Summary (Both EGP and USD)
DROP FUNCTION IF EXISTS public.get_employee_balance_summary(UUID);

CREATE OR REPLACE FUNCTION public.get_employee_balance_summary(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_egp_received NUMERIC := 0.0;
    v_egp_adjust_sub NUMERIC := 0.0;
    v_egp_spent NUMERIC := 0.0;
    v_egp_available NUMERIC := 0.0;

    v_usd_received NUMERIC := 0.0;
    v_usd_adjust_sub NUMERIC := 0.0;
    v_usd_spent NUMERIC := 0.0;
    v_usd_available NUMERIC := 0.0;
BEGIN
    -- EGP
    SELECT COALESCE(SUM(amount), 0.0) INTO v_egp_received
    FROM public.employee_balance_transactions
    WHERE user_id = p_user_id AND currency = 'EGP' AND type IN ('credit', 'adjustment_add');

    SELECT COALESCE(SUM(amount), 0.0) INTO v_egp_adjust_sub
    FROM public.employee_balance_transactions
    WHERE user_id = p_user_id AND currency = 'EGP' AND type = 'adjustment_sub';

    SELECT COALESCE(SUM(amount), 0.0) INTO v_egp_spent
    FROM public.expenses
    WHERE user_id = p_user_id AND currency = 'EGP';

    v_egp_available := (v_egp_received - v_egp_adjust_sub - v_egp_spent);

    -- USD
    SELECT COALESCE(SUM(amount), 0.0) INTO v_usd_received
    FROM public.employee_balance_transactions
    WHERE user_id = p_user_id AND currency = 'USD' AND type IN ('credit', 'adjustment_add');

    SELECT COALESCE(SUM(amount), 0.0) INTO v_usd_adjust_sub
    FROM public.employee_balance_transactions
    WHERE user_id = p_user_id AND currency = 'USD' AND type = 'adjustment_sub';

    SELECT COALESCE(SUM(amount), 0.0) INTO v_usd_spent
    FROM public.expenses
    WHERE user_id = p_user_id AND currency = 'USD';

    v_usd_available := (v_usd_received - v_usd_adjust_sub - v_usd_spent);

    RETURN json_build_object(
        'user_id', p_user_id,
        'egp', json_build_object(
            'total_received', v_egp_received,
            'total_adjust_sub', v_egp_adjust_sub,
            'total_spent', v_egp_spent,
            'available_balance', v_egp_available
        ),
        'usd', json_build_object(
            'total_received', v_usd_received,
            'total_adjust_sub', v_usd_adjust_sub,
            'total_spent', v_usd_spent,
            'available_balance', v_usd_available
        ),
        -- Backward-compatibility fields mapping to primary EGP
        'total_received', v_egp_received,
        'total_spent', v_egp_spent,
        'available_balance', v_egp_available
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- 5. Get All Employee Balances (Multi-Currency Support)
-- Explicitly drop old function whose return table structure had 10 columns (now 16 columns) to avoid 42P13
DROP FUNCTION IF EXISTS public.get_all_employee_balances();

CREATE OR REPLACE FUNCTION public.get_all_employee_balances()
RETURNS TABLE (
    user_id UUID,
    name TEXT,
    email TEXT,
    role TEXT,
    status TEXT,
    avatar_url TEXT,
    egp_received NUMERIC,
    egp_spent NUMERIC,
    egp_available NUMERIC,
    usd_received NUMERIC,
    usd_spent NUMERIC,
    usd_available NUMERIC,
    total_received NUMERIC,
    total_spent NUMERIC,
    available_balance NUMERIC,
    last_allowance_date DATE
) AS $$
BEGIN
    RETURN QUERY
    WITH egp_tx AS (
        SELECT
            tx.user_id AS uid,
            COALESCE(SUM(CASE WHEN tx.type IN ('credit', 'adjustment_add') THEN tx.amount ELSE -tx.amount END), 0.0) AS net_credit,
            COALESCE(SUM(CASE WHEN tx.type IN ('credit', 'adjustment_add') THEN tx.amount ELSE 0.0 END), 0.0) AS total_rec,
            MAX(tx.transaction_date) AS last_date
        FROM public.employee_balance_transactions tx
        WHERE tx.currency = 'EGP'
        GROUP BY tx.user_id
    ),
    egp_exp AS (
        SELECT
            e.user_id AS uid,
            COALESCE(SUM(e.amount), 0.0) AS total_sp
        FROM public.expenses e
        WHERE e.currency = 'EGP'
        GROUP BY e.user_id
    ),
    usd_tx AS (
        SELECT
            tx.user_id AS uid,
            COALESCE(SUM(CASE WHEN tx.type IN ('credit', 'adjustment_add') THEN tx.amount ELSE -tx.amount END), 0.0) AS net_credit,
            COALESCE(SUM(CASE WHEN tx.type IN ('credit', 'adjustment_add') THEN tx.amount ELSE 0.0 END), 0.0) AS total_rec,
            MAX(tx.transaction_date) AS last_date
        FROM public.employee_balance_transactions tx
        WHERE tx.currency = 'USD'
        GROUP BY tx.user_id
    ),
    usd_exp AS (
        SELECT
            e.user_id AS uid,
            COALESCE(SUM(e.amount), 0.0) AS total_sp
        FROM public.expenses e
        WHERE e.currency = 'USD'
        GROUP BY e.user_id
    )
    SELECT
        p.id AS user_id,
        COALESCE(p.full_name, 'مستخدم') AS name,
        p.email,
        p.role,
        p.status,
        p.avatar_url,
        COALESCE(etx.total_rec, 0.0) AS egp_received,
        COALESCE(eexp.total_sp, 0.0) AS egp_spent,
        (COALESCE(etx.net_credit, 0.0) - COALESCE(eexp.total_sp, 0.0)) AS egp_available,
        COALESCE(utx.total_rec, 0.0) AS usd_received,
        COALESCE(uexp.total_sp, 0.0) AS usd_spent,
        (COALESCE(utx.net_credit, 0.0) - COALESCE(uexp.total_sp, 0.0)) AS usd_available,
        COALESCE(etx.total_rec, 0.0) AS total_received,
        COALESCE(eexp.total_sp, 0.0) AS total_spent,
        (COALESCE(etx.net_credit, 0.0) - COALESCE(eexp.total_sp, 0.0)) AS available_balance,
        GREATEST(etx.last_date, utx.last_date) AS last_allowance_date
    FROM public.profiles p
    LEFT JOIN egp_tx etx ON etx.uid = p.id
    LEFT JOIN egp_exp eexp ON eexp.uid = p.id
    LEFT JOIN usd_tx utx ON utx.uid = p.id
    LEFT JOIN usd_exp uexp ON uexp.uid = p.id
    ORDER BY COALESCE(p.full_name, 'مستخدم') ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- 6. Server-Side Atomic Currency-Aware Balance Enforcement Trigger on public.expenses
CREATE OR REPLACE FUNCTION public.enforce_expense_balance_limit()
RETURNS TRIGGER AS $$
DECLARE
    v_user_role TEXT;
    v_available NUMERIC;
    v_target_currency TEXT;
BEGIN
    v_target_currency := COALESCE(NEW.currency, 'EGP');

    -- Acquire currency-specific advisory lock for this user to serialize concurrent operations
    PERFORM pg_advisory_xact_lock(hashtext(NEW.user_id::text || '_' || v_target_currency));

    -- Check user role
    SELECT role INTO v_user_role FROM public.profiles WHERE id = NEW.user_id;

    -- Enforce for employees and regular users (admins exempt)
    IF v_user_role = 'employee' OR v_user_role IS NULL THEN
        IF TG_OP = 'INSERT' THEN
            v_available := public.get_employee_available_balance(NEW.user_id, v_target_currency);
            IF NEW.amount > v_available THEN
                RAISE EXCEPTION 'INSUFFICIENT_BALANCE: Expense amount (% %) exceeds available balance (% %)',
                    NEW.amount, v_target_currency, v_available, v_target_currency;
            END IF;
        ELSIF TG_OP = 'UPDATE' THEN
            -- If user or currency changed
            IF NEW.user_id <> OLD.user_id OR NEW.currency <> OLD.currency THEN
                -- Also lock old user/currency
                PERFORM pg_advisory_xact_lock(hashtext(OLD.user_id::text || '_' || OLD.currency));
                v_available := public.get_employee_available_balance(NEW.user_id, v_target_currency);
                IF NEW.amount > v_available THEN
                    RAISE EXCEPTION 'INSUFFICIENT_BALANCE: Expense amount (% %) exceeds available balance (% %)',
                        NEW.amount, v_target_currency, v_available, v_target_currency;
                END IF;
            -- Same user and currency: if amount increased, verify delta
            ELSIF NEW.amount > OLD.amount THEN
                v_available := public.get_employee_available_balance(NEW.user_id, v_target_currency);
                IF (NEW.amount - OLD.amount) > v_available THEN
                    RAISE EXCEPTION 'INSUFFICIENT_BALANCE: Additional expense amount (% %) exceeds available balance (% %)',
                        (NEW.amount - OLD.amount), v_target_currency, v_available, v_target_currency;
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

-- 7. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
