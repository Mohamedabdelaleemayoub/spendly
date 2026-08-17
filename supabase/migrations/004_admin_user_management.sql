-- ==============================================================================
-- Spendly - Migration 004: Admin User Management & User Status
-- Purpose: Add status column ('active' | 'inactive') to profiles and safe helper functions
-- ==============================================================================

-- 1. Safely add status column to public.profiles if not present
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive'));

CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(status);

-- 2. Update handle_new_user() trigger function to explicitly set default status
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, role, status)
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'name',
            split_part(NEW.email, '@', 1),
            'مستخدم'
        ),
        NEW.email,
        'employee', -- Default role is ALWAYS employee
        'active'    -- Default status is ALWAYS active
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. Helper function: Count active admins
CREATE OR REPLACE FUNCTION public.count_active_admins()
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER 
        FROM public.profiles 
        WHERE role = 'admin' AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- 4. Trigger to protect status tampering by non-admins
CREATE OR REPLACE FUNCTION public.protect_profile_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        IF NOT public.is_admin() THEN
            RAISE EXCEPTION 'غير مصرح لك بتعديل حالة الحساب. وحده المشرف (Admin) يمكنه تعديل الحالة.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_protect_profile_status ON public.profiles;
CREATE TRIGGER on_protect_profile_status
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.protect_profile_status();

-- 5. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
