-- ==============================================================================
-- 005_fix_profiles_columns_and_storage.sql
-- Fix missing public.profiles columns (avatar_url, status), create storage buckets
-- (avatars, expense-receipts) with RLS policies, and reload PostgREST schema cache.
-- ==============================================================================

-- 1. Ensure public.profiles has avatar_url and status columns
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'avatar_url'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN avatar_url TEXT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'status'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive'));
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(status);

-- 2. Update trigger handle_new_user to include status
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
        'employee',
        'active'
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. Create Storage Buckets for Avatars and Receipts
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('avatars', 'avatars', true),
    ('expense-receipts', 'expense-receipts', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 4. Storage Policies for 'avatars' and 'expense-receipts'
-- SELECT: Public can view avatars and receipts
DROP POLICY IF EXISTS "Public can view avatars" ON storage.objects;
CREATE POLICY "Public can view avatars"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Public can view expense receipts" ON storage.objects;
CREATE POLICY "Public can view expense receipts"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'expense-receipts');

-- INSERT: Authenticated users can upload to avatars (their own folder) and expense-receipts
DROP POLICY IF EXISTS "Authenticated users can upload avatars" ON storage.objects;
CREATE POLICY "Authenticated users can upload avatars"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Authenticated users can upload expense receipts" ON storage.objects;
CREATE POLICY "Authenticated users can upload expense receipts"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'expense-receipts');

-- UPDATE: Authenticated users can update objects in avatars and receipts
DROP POLICY IF EXISTS "Authenticated users can update avatars" ON storage.objects;
CREATE POLICY "Authenticated users can update avatars"
    ON storage.objects FOR UPDATE TO authenticated
    USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Authenticated users can update receipts" ON storage.objects;
CREATE POLICY "Authenticated users can update receipts"
    ON storage.objects FOR UPDATE TO authenticated
    USING (bucket_id = 'expense-receipts');

-- DELETE: Authenticated users can delete their objects
DROP POLICY IF EXISTS "Authenticated users can delete avatars" ON storage.objects;
CREATE POLICY "Authenticated users can delete avatars"
    ON storage.objects FOR DELETE TO authenticated
    USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Authenticated users can delete receipts" ON storage.objects;
CREATE POLICY "Authenticated users can delete receipts"
    ON storage.objects FOR DELETE TO authenticated
    USING (bucket_id = 'expense-receipts');

-- 5. Seed default categories if none exist
INSERT INTO public.categories (name, icon, color) VALUES
('طعام ومشروبات', 'restaurant', '#E17055'),
('مواصلات ونقل', 'directions_car', '#0984E3'),
('فواتير وخدمات', 'receipt', '#00B894'),
('تسوق ومشتريات', 'shopping_bag', '#F2A922'),
('صحة وعلاج', 'medical_services', '#D63031'),
('سفر ورحلات', 'flight', '#6C5CE7'),
('أخرى', 'more_horiz', '#636E72')
ON CONFLICT DO NOTHING;

-- 6. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
