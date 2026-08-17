-- ==============================================================================
-- Spendly - Complete Production Database Schema, RLS, Functions & Triggers
-- Run this in Supabase Dashboard -> SQL Editor -> New Query -> Run
-- ==============================================================================

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. Profiles Table
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL DEFAULT 'مستخدم',
    email TEXT,
    role TEXT NOT NULL DEFAULT 'employee' CHECK (role IN ('admin', 'employee')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Backward compatibility: if older schema created column "name", rename to full_name
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'name'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'full_name'
    ) THEN
        ALTER TABLE public.profiles RENAME COLUMN name TO full_name;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ── Secure Admin Check Helper (Prevents RLS Recursion) ────────────────────────
-- STABLE + SECURITY DEFINER ensures this runs with database owner privileges
-- without triggering recursive RLS evaluation on profiles.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- Drop existing policies on profiles
DROP POLICY IF EXISTS "Users can view their own profile or admin can view all" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;

-- ── Profiles RLS Policies ───────────────────────────────────────────────────
-- SELECT: Employee can view ONLY their own profile; Admin can view ALL profiles
CREATE POLICY "Users can view their own profile or admin can view all"
    ON public.profiles FOR SELECT TO authenticated
    USING (auth.uid() = id OR public.is_admin());

-- UPDATE: Users can update their own profile fields
CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- INSERT: Users can insert their own profile
CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = id);

-- ── Trigger: Update timestamp ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_profiles_updated ON public.profiles;
CREATE TRIGGER on_profiles_updated
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ── Trigger: Protect Profile Role from Client Tampering ─────────────────────
-- A normal employee must NEVER be able to change their role to 'admin'.
CREATE OR REPLACE FUNCTION public.protect_profile_role()
RETURNS TRIGGER AS $$
BEGIN
    -- If role is being changed, verify caller is already an admin
    IF NEW.role IS DISTINCT FROM OLD.role THEN
        IF NOT public.is_admin() THEN
            RAISE EXCEPTION 'غير مصرح لك بتغيير الصلاحيات. وحده المشرف (Admin) يمكنه تعديل الصلاحيات.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_protect_profile_role ON public.profiles;
CREATE TRIGGER on_protect_profile_role
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.protect_profile_role();

-- ── Trigger: Automatic Profile Creation on auth.users Sign Up ────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, role)
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'name',
            split_part(NEW.email, '@', 1),
            'مستخدم'
        ),
        NEW.email,
        'employee' -- Default role is ALWAYS employee
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Backfill profile rows for any existing users in auth.users
INSERT INTO public.profiles (id, full_name, email, role)
SELECT 
    id,
    COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', split_part(email, '@', 1), 'مستخدم'),
    email,
    'employee'
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- ==============================================================================
-- 3. Categories Table
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    icon TEXT NOT NULL DEFAULT 'category',
    color TEXT NOT NULL DEFAULT '#0D7377',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Backward compatibility: If an earlier version created 'user_id' with NOT NULL, drop it
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'categories' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.categories ALTER COLUMN user_id DROP NOT NULL;
    END IF;
END $$;

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can view categories" ON public.categories;
DROP POLICY IF EXISTS "Users can view their own categories or admin can view all" ON public.categories;
DROP POLICY IF EXISTS "Users can view their own categories" ON public.categories;
DROP POLICY IF EXISTS "Users can insert their own categories" ON public.categories;
DROP POLICY IF EXISTS "Users can update their own categories" ON public.categories;
DROP POLICY IF EXISTS "Users can delete their own categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can insert categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can update categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can delete categories" ON public.categories;

-- ── Categories RLS Policies ─────────────────────────────────────────────────
-- SELECT: All authenticated users (employees and admins) can view company categories
CREATE POLICY "Authenticated users can view categories"
    ON public.categories FOR SELECT TO authenticated
    USING (true);

-- INSERT: Only Admins can create global categories
CREATE POLICY "Admins can insert categories"
    ON public.categories FOR INSERT TO authenticated
    WITH CHECK (public.is_admin());

-- UPDATE: Only Admins can update categories
CREATE POLICY "Admins can update categories"
    ON public.categories FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- DELETE: Only Admins can delete categories
CREATE POLICY "Admins can delete categories"
    ON public.categories FOR DELETE TO authenticated
    USING (public.is_admin());

DROP TRIGGER IF EXISTS on_categories_updated ON public.categories;
CREATE TRIGGER on_categories_updated
    BEFORE UPDATE ON public.categories
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Seed Default Global Categories
INSERT INTO public.categories (name, icon, color) VALUES
('طعام ومشروبات', 'restaurant', '#E17055'),
('مواصلات ونقل', 'directions_car', '#0984E3'),
('فواتير وخدمات', 'receipt', '#00B894'),
('تسوق ومشتريات', 'shopping_bag', '#F2A922'),
('صحة وعلاج', 'medical_services', '#D63031'),
('سفر ورحلات', 'flight', '#6C5CE7'),
('أخرى', 'more_horiz', '#636E72')
ON CONFLICT DO NOTHING;

-- ==============================================================================
-- 4. Expenses Table
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    notes TEXT,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    payment_method TEXT NOT NULL DEFAULT 'cash' CHECK (payment_method IN ('cash', 'bank', 'wallet', 'transfer')),
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    receipt_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Backward compatibility: Ensure description and notes columns exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'expenses' AND column_name = 'description'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN description TEXT;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'expenses' AND column_name = 'notes'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN notes TEXT;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON public.expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_expense_date ON public.expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON public.expenses(user_id, expense_date DESC);

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Employees can select own expenses or Admins can select all expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can select own expenses or Admins can select all" ON public.expenses;
DROP POLICY IF EXISTS "Users can view their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can insert their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can update their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can update own expenses or Admins can update any" ON public.expenses;
DROP POLICY IF EXISTS "Users can delete their own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can delete own expenses or Admins can delete any" ON public.expenses;

-- ── Expenses RLS Policies ───────────────────────────────────────────────────
-- 1. SELECT:
-- Employee: auth.uid() = user_id (only their own expenses)
-- Admin: can view all expenses across all employees
CREATE POLICY "Users can select own expenses or Admins can select all"
    ON public.expenses FOR SELECT TO authenticated
    USING (auth.uid() = user_id OR public.is_admin());

-- 2. INSERT:
-- Both Employee and Admin can only insert expenses for their own user_id
CREATE POLICY "Users can insert their own expenses"
    ON public.expenses FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- 3. UPDATE:
-- Employee and Admin can ONLY update their OWN expenses
CREATE POLICY "Users can update their own expenses"
    ON public.expenses FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 4. DELETE:
-- Employee and Admin can ONLY delete their OWN expenses
CREATE POLICY "Users can delete their own expenses"
    ON public.expenses FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

DROP TRIGGER IF EXISTS on_expenses_updated ON public.expenses;
CREATE TRIGGER on_expenses_updated
    BEFORE UPDATE ON public.expenses
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 5. Storage Bucket (for Receipts)
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('expense-receipts', 'expense-receipts', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Authenticated users can upload receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own receipts" ON storage.objects;
DROP POLICY IF EXISTS "Public read for receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own receipts or Admin can delete" ON storage.objects;

CREATE POLICY "Authenticated users can upload receipts"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'expense-receipts' AND (auth.uid())::text = (storage.foldername(name))[1]);

CREATE POLICY "Public read for receipts"
    ON storage.objects FOR SELECT TO public
    USING (bucket_id = 'expense-receipts');

CREATE POLICY "Users can delete own receipts or Admin can delete"
    ON storage.objects FOR DELETE TO authenticated
    USING (bucket_id = 'expense-receipts' AND ((auth.uid())::text = (storage.foldername(name))[1] OR public.is_admin()));

-- ==============================================================================
-- 6. Explicit PostgREST & Role Permissions
-- ==============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;

-- ==============================================================================
-- 7. Force PostgREST to reload its schema cache immediately
-- ==============================================================================
NOTIFY pgrst, 'reload schema';
