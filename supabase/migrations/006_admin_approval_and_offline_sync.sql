-- ==============================================================================
-- Spendly - Migration 006: Admin Approval for New Users, Notifications & Offline Sync
-- Purpose:
-- 1. App Settings table for storing 'require_admin_approval'
-- 2. Update profiles status CHECK to ('active', 'inactive', 'pending', 'rejected')
-- 3. Automatic user status determination based on approval setting
-- 4. Admin in-app notifications table & trigger for pending registrations
-- 5. Server-side RLS enforcement: Pending / Rejected / Inactive users cannot access data
-- 6. Expenses table updates: optional title, idempotent client UUID support
-- ==============================================================================

-- ── 1. App Settings Table ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.app_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL
);

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Helper to safely check if caller is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- Helper to check if caller is an active user (either employee or admin)
CREATE OR REPLACE FUNCTION public.is_active_authenticated_user()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- Drop previous app_settings policies if existing
DROP POLICY IF EXISTS "Authenticated users can read app settings" ON public.app_settings;
DROP POLICY IF EXISTS "Only admins can modify app settings" ON public.app_settings;
DROP POLICY IF EXISTS "Only admins can insert app settings" ON public.app_settings;
DROP POLICY IF EXISTS "Only admins can delete app settings" ON public.app_settings;

CREATE POLICY "Authenticated users can read app settings"
    ON public.app_settings FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "Only admins can modify app settings"
    ON public.app_settings FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

CREATE POLICY "Only admins can insert app settings"
    ON public.app_settings FOR INSERT TO authenticated
    WITH CHECK (public.is_admin());

CREATE POLICY "Only admins can delete app settings"
    ON public.app_settings FOR DELETE TO authenticated
    USING (public.is_admin());

-- Seed default setting: require_admin_approval = false
INSERT INTO public.app_settings (key, value, description)
VALUES ('require_admin_approval', '{"enabled": false}'::jsonb, 'Require admin approval before new users can access the application')
ON CONFLICT (key) DO NOTHING;

-- Helper function to read a boolean setting safely from SQL / triggers
CREATE OR REPLACE FUNCTION public.get_setting_bool(setting_key TEXT, default_val BOOLEAN)
RETURNS BOOLEAN AS $$
DECLARE
    setting_val JSONB;
BEGIN
    SELECT value INTO setting_val FROM public.app_settings WHERE key = setting_key;
    IF setting_val IS NULL THEN
        RETURN default_val;
    END IF;
    IF setting_val ? 'enabled' THEN
        RETURN (setting_val->>'enabled')::BOOLEAN;
    END IF;
    RETURN default_val;
EXCEPTION
    WHEN OTHERS THEN
        RETURN default_val;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- ── 2. Update Profiles Status CHECK constraint ──────────────────────────────
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT tc.constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.check_constraints cc
            ON tc.constraint_name = cc.constraint_name
        WHERE tc.table_schema = 'public'
          AND tc.table_name = 'profiles'
          AND cc.check_clause LIKE '%status%'
    ) LOOP
        EXECUTE 'ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
    END LOOP;
END $$;

ALTER TABLE public.profiles
    ADD CONSTRAINT profiles_status_check
    CHECK (status IN ('active', 'inactive', 'pending', 'rejected'));

-- Update handle_new_user() trigger to inspect require_admin_approval
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    requires_approval BOOLEAN;
    initial_status TEXT;
BEGIN
    -- Determine if admin approval is enabled
    requires_approval := public.get_setting_bool('require_admin_approval', false);
    
    IF requires_approval THEN
        initial_status := 'pending';
    ELSE
        initial_status := 'active';
    END IF;

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
        'employee', -- Default role is always employee
        initial_status
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger to protect status tampering by non-admins
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

-- ── 3. Admin In-App Notifications Table ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL DEFAULT 'registration_request',
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_admin_notifications_user_id ON public.admin_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_is_read ON public.admin_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_created_at ON public.admin_notifications(created_at DESC);

ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view notifications" ON public.admin_notifications;
DROP POLICY IF EXISTS "Admins can update notifications" ON public.admin_notifications;
DROP POLICY IF EXISTS "Admins can delete notifications" ON public.admin_notifications;

CREATE POLICY "Admins can view notifications"
    ON public.admin_notifications FOR SELECT TO authenticated
    USING (public.is_admin());

CREATE POLICY "Admins can update notifications"
    ON public.admin_notifications FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

CREATE POLICY "Admins can delete notifications"
    ON public.admin_notifications FOR DELETE TO authenticated
    USING (public.is_admin());

-- Trigger to automatically create admin notification when a profile has status = 'pending'
CREATE OR REPLACE FUNCTION public.handle_pending_profile_notification()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT' AND NEW.status = 'pending') OR 
       (TG_OP = 'UPDATE' AND NEW.status = 'pending' AND OLD.status IS DISTINCT FROM 'pending') THEN
        INSERT INTO public.admin_notifications (type, title, message, user_id)
        VALUES (
            'registration_request',
            'طلب تسجيل جديد',
            'يرغب ' || COALESCE(NEW.full_name, 'مستخدم جديد') || ' (' || COALESCE(NEW.email, '') || ') بالانضمام إلى Spendly.',
            NEW.id
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_pending_profile_notification ON public.profiles;
CREATE TRIGGER on_pending_profile_notification
    AFTER INSERT OR UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_pending_profile_notification();

-- ── 4. Server-Side Access Enforcement (RLS Policies) ────────────────────────
-- Pending, Rejected, and Inactive users must NOT be allowed to access application data.

-- Profiles table SELECT: Allow pending/rejected users to read ONLY their OWN profile (so they can see their status), admins can read all
DROP POLICY IF EXISTS "Users can view their own profile or admin can view all" ON public.profiles;
CREATE POLICY "Users can view their own profile or admin can view all"
    ON public.profiles FOR SELECT TO authenticated
    USING (auth.uid() = id OR public.is_admin());

-- Categories table: Only ACTIVE authenticated users or admins can SELECT categories
DROP POLICY IF EXISTS "Authenticated users can view categories" ON public.categories;
CREATE POLICY "Authenticated users can view categories"
    ON public.categories FOR SELECT TO authenticated
    USING (public.is_active_authenticated_user() OR public.is_admin());

-- Expenses table: Only ACTIVE authenticated users or admins can access/manipulate expenses
DROP POLICY IF EXISTS "Users can select own expenses or Admins can select all" ON public.expenses;
DROP POLICY IF EXISTS "Users can insert their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can update their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can delete their own expenses" ON public.expenses;

CREATE POLICY "Users can select own expenses or Admins can select all"
    ON public.expenses FOR SELECT TO authenticated
    USING ((auth.uid() = user_id AND public.is_active_authenticated_user()) OR public.is_admin());

CREATE POLICY "Users can insert their own expenses"
    ON public.expenses FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id AND (public.is_active_authenticated_user() OR public.is_admin()));

CREATE POLICY "Users can update their own expenses"
    ON public.expenses FOR UPDATE TO authenticated
    USING (auth.uid() = user_id AND (public.is_active_authenticated_user() OR public.is_admin()))
    WITH CHECK (auth.uid() = user_id AND (public.is_active_authenticated_user() OR public.is_admin()));

CREATE POLICY "Users can delete their own expenses"
    ON public.expenses FOR DELETE TO authenticated
    USING (auth.uid() = user_id AND (public.is_active_authenticated_user() OR public.is_admin()));

-- ── 5. Expenses Schema Updates: Optional Title ──────────────────────────────
ALTER TABLE public.expenses ALTER COLUMN title DROP NOT NULL;
ALTER TABLE public.expenses ALTER COLUMN title SET DEFAULT '';

-- Ensure category_id has index
CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON public.expenses(category_id);

-- ── 6. Permissions & Schema Cache Reload ────────────────────────────────────
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;

NOTIFY pgrst, 'reload schema';
