-- ==============================================================================
-- Spendly - Migration 019: Employee Payroll & Salary Schedule
-- Purpose:
-- 1. Add configurable salary cycle fields to public.profiles
-- 2. Create public.employee_salary_payments table for official payroll history
-- 3. Strict Row Level Security (RLS) policies for Admins & Employees
-- 4. Server-side triggers and timestamp handlers
-- 5. RPC for aggregated Admin Payroll Overview & Cash-Flow Planning
-- ==============================================================================

-- ── 1. Update Profiles Table with Salary Cycle Configurations ────────────────
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS salary_cycle_type TEXT NOT NULL DEFAULT 'monthly' CHECK (salary_cycle_type IN ('monthly', 'custom_days')),
    ADD COLUMN IF NOT EXISTS salary_cycle_days INT NOT NULL DEFAULT 30 CHECK (salary_cycle_days >= 1 AND salary_cycle_days <= 365),
    ADD COLUMN IF NOT EXISTS salary_cycle_start_day INT NOT NULL DEFAULT 1 CHECK (salary_cycle_start_day >= 1 AND salary_cycle_start_day <= 31);

CREATE INDEX IF NOT EXISTS idx_profiles_salary_cycle ON public.profiles(salary_cycle_type, salary_cycle_start_day);

-- Update protect_profile_salary trigger to safeguard salary cycle configuration
CREATE OR REPLACE FUNCTION public.protect_profile_salary()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.salary_amount IS DISTINCT FROM OLD.salary_amount OR 
        NEW.salary_currency IS DISTINCT FROM OLD.salary_currency OR
        NEW.salary_cycle_type IS DISTINCT FROM OLD.salary_cycle_type OR
        NEW.salary_cycle_days IS DISTINCT FROM OLD.salary_cycle_days OR
        NEW.salary_cycle_start_day IS DISTINCT FROM OLD.salary_cycle_start_day) THEN
        IF NOT public.is_admin() THEN
            RAISE EXCEPTION 'غير مصرح لك بتعديل الراتب أو دورة الصرف. وحده المشرف (Admin) يمكنه تعديل إعدادات الرواتب.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ── 2. Create Employee Salary Payments Table ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.employee_salary_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    currency TEXT NOT NULL DEFAULT 'EGP' CHECK (currency IN ('EGP', 'USD')),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    salary_period_start DATE NOT NULL,
    salary_period_end DATE NOT NULL,
    note TEXT NULL,
    created_by UUID NOT NULL REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT chk_salary_period CHECK (salary_period_end >= salary_period_start)
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_salary_payments_user_id ON public.employee_salary_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_salary_payments_payment_date ON public.employee_salary_payments(payment_date DESC);
CREATE INDEX IF NOT EXISTS idx_salary_payments_period ON public.employee_salary_payments(salary_period_start, salary_period_end);
CREATE INDEX IF NOT EXISTS idx_salary_payments_currency ON public.employee_salary_payments(currency);
CREATE INDEX IF NOT EXISTS idx_salary_payments_created_by ON public.employee_salary_payments(created_by);

-- Updated_at Trigger
CREATE OR REPLACE FUNCTION public.handle_salary_payments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_salary_payment_updated ON public.employee_salary_payments;
CREATE TRIGGER on_salary_payment_updated
    BEFORE UPDATE ON public.employee_salary_payments
    FOR EACH ROW EXECUTE FUNCTION public.handle_salary_payments_updated_at();

-- ── 3. Row Level Security (RLS) ──────────────────────────────────────────────
ALTER TABLE public.employee_salary_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view all salary payments" ON public.employee_salary_payments;
DROP POLICY IF EXISTS "Employees can view own salary payments" ON public.employee_salary_payments;
DROP POLICY IF EXISTS "Admins can insert salary payments" ON public.employee_salary_payments;
DROP POLICY IF EXISTS "Admins can update salary payments" ON public.employee_salary_payments;
DROP POLICY IF EXISTS "Admins can delete salary payments" ON public.employee_salary_payments;

-- SELECT: Admins can view all payments, Employees can view only their own payments
CREATE POLICY "Admins can view all salary payments"
    ON public.employee_salary_payments FOR SELECT TO authenticated
    USING (public.is_admin());

CREATE POLICY "Employees can view own salary payments"
    ON public.employee_salary_payments FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- INSERT: Only administrators can insert payments, enforcing created_by = auth.uid()
CREATE POLICY "Admins can insert salary payments"
    ON public.employee_salary_payments FOR INSERT TO authenticated
    WITH CHECK (public.is_admin() AND created_by = auth.uid());

-- UPDATE: Only administrators can update salary payments
CREATE POLICY "Admins can update salary payments"
    ON public.employee_salary_payments FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- DELETE: Only administrators can delete salary payments
CREATE POLICY "Admins can delete salary payments"
    ON public.employee_salary_payments FOR DELETE TO authenticated
    USING (public.is_admin());

-- ── 4. Admin Payroll Overview RPC ───────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_admin_payroll_overview()
RETURNS TABLE (
    user_id UUID,
    full_name TEXT,
    email TEXT,
    avatar_url TEXT,
    salary_amount NUMERIC(12,2),
    salary_currency TEXT,
    salary_cycle_type TEXT,
    salary_cycle_days INT,
    salary_cycle_start_day INT,
    total_paid NUMERIC(12,2),
    last_payment_date DATE,
    last_payment_amount NUMERIC(12,2),
    payment_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id AS user_id,
        p.full_name,
        p.email,
        p.avatar_url,
        COALESCE(p.salary_amount, 0.00) AS salary_amount,
        COALESCE(p.salary_currency, 'EGP') AS salary_currency,
        COALESCE(p.salary_cycle_type, 'monthly') AS salary_cycle_type,
        COALESCE(p.salary_cycle_days, 30) AS salary_cycle_days,
        COALESCE(p.salary_cycle_start_day, 1) AS salary_cycle_start_day,
        COALESCE(SUM(sp.amount), 0.00) AS total_paid,
        MAX(sp.payment_date) AS last_payment_date,
        (
            SELECT sp2.amount 
            FROM public.employee_salary_payments sp2 
            WHERE sp2.user_id = p.id 
            ORDER BY sp2.payment_date DESC, sp2.created_at DESC 
            LIMIT 1
        ) AS last_payment_amount,
        COUNT(sp.id) AS payment_count
    FROM public.profiles p
    LEFT JOIN public.employee_salary_payments sp ON p.id = sp.user_id
    WHERE p.status = 'active'
    GROUP BY p.id, p.full_name, p.email, p.avatar_url, p.salary_amount, p.salary_currency, p.salary_cycle_type, p.salary_cycle_days, p.salary_cycle_start_day
    ORDER BY p.full_name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant RPC execution permissions
GRANT EXECUTE ON FUNCTION public.get_admin_payroll_overview() TO authenticated;

-- ── 5. Reload PostgREST Schema Cache ─────────────────────────────────────────
NOTIFY pgrst, 'reload schema';
