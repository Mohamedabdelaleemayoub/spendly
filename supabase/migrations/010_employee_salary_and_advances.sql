-- ==============================================================================
-- Spendly - Migration 010: Employee Salary & Salary Advances
-- Purpose:
-- 1. Add salary_amount and salary_currency to public.profiles with protection trigger
-- 2. Create employee_salary_advances table with check constraints and indexes
-- 3. Strict Admin-only RLS policies for salary advances
-- 4. Server-side timestamp triggers
-- ==============================================================================

-- ── 1. Update Profiles Table with Salary Fields ──────────────────────────────
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS salary_amount NUMERIC(12,2) DEFAULT 0.00 CHECK (salary_amount >= 0),
    ADD COLUMN IF NOT EXISTS salary_currency TEXT NOT NULL DEFAULT 'EGP' CHECK (salary_currency IN ('EGP', 'USD'));

CREATE INDEX IF NOT EXISTS idx_profiles_salary ON public.profiles(salary_amount, salary_currency);

-- Trigger to prevent employees from modifying their own salary fields
CREATE OR REPLACE FUNCTION public.protect_profile_salary()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.salary_amount IS DISTINCT FROM OLD.salary_amount OR 
        NEW.salary_currency IS DISTINCT FROM OLD.salary_currency) THEN
        IF NOT public.is_admin() THEN
            RAISE EXCEPTION 'غير مصرح لك بتعديل الراتب. وحده المشرف (Admin) يمكنه تعديل راتب الموظف.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_protect_profile_salary ON public.profiles;
CREATE TRIGGER on_protect_profile_salary
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.protect_profile_salary();

-- ── 2. Create Employee Salary Advances Table ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.employee_salary_advances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    currency TEXT NOT NULL DEFAULT 'EGP' CHECK (currency IN ('EGP', 'USD')),
    advance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT NULL,
    created_by UUID NOT NULL REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_salary_advances_user_id ON public.employee_salary_advances(user_id);
CREATE INDEX IF NOT EXISTS idx_salary_advances_date ON public.employee_salary_advances(advance_date DESC);
CREATE INDEX IF NOT EXISTS idx_salary_advances_created_by ON public.employee_salary_advances(created_by);

-- Updated_at Trigger
CREATE OR REPLACE FUNCTION public.handle_salary_advances_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_salary_advance_updated ON public.employee_salary_advances;
CREATE TRIGGER on_salary_advance_updated
    BEFORE UPDATE ON public.employee_salary_advances
    FOR EACH ROW EXECUTE FUNCTION public.handle_salary_advances_updated_at();

-- ── 3. Strict Admin-Only Row Level Security (RLS) ───────────────────────────
ALTER TABLE public.employee_salary_advances ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view salary advances" ON public.employee_salary_advances;
DROP POLICY IF EXISTS "Admins can insert salary advances" ON public.employee_salary_advances;
DROP POLICY IF EXISTS "Admins can update salary advances" ON public.employee_salary_advances;
DROP POLICY IF EXISTS "Admins can delete salary advances" ON public.employee_salary_advances;

-- SELECT: Only administrators can view salary advances
CREATE POLICY "Admins can view salary advances"
    ON public.employee_salary_advances FOR SELECT TO authenticated
    USING (public.is_admin());

-- INSERT: Only administrators can insert advances, enforcing created_by = auth.uid()
CREATE POLICY "Admins can insert salary advances"
    ON public.employee_salary_advances FOR INSERT TO authenticated
    WITH CHECK (public.is_admin() AND created_by = auth.uid());

-- UPDATE: Only administrators can update salary advances
CREATE POLICY "Admins can update salary advances"
    ON public.employee_salary_advances FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- DELETE: Only administrators can delete salary advances
CREATE POLICY "Admins can delete salary advances"
    ON public.employee_salary_advances FOR DELETE TO authenticated
    USING (public.is_admin());

-- ── 4. Reload PostgREST Schema Cache ─────────────────────────────────────────
NOTIFY pgrst, 'reload schema';
