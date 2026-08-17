-- ==============================================================================
-- Spendly - Migration 003: Profile Settings & Avatar Storage
-- Purpose: Add avatar_url column to profiles and configure profile-images bucket
-- ==============================================================================

-- 1. Safely add avatar_url column to public.profiles if not present
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 2. Create profile-images public bucket if it does not already exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Storage RLS Policies for profile-images
-- Policy: Anyone authenticated or public can view profile images
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
          AND tablename = 'objects' 
          AND policyname = 'Public profile image access'
    ) THEN
        CREATE POLICY "Public profile image access"
            ON storage.objects FOR SELECT
            USING (bucket_id = 'profile-images');
    END IF;
END $$;

-- Policy: Authenticated user can upload only to their own folder: {auth.uid()}/...
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
          AND tablename = 'objects' 
          AND policyname = 'Users can upload own profile image'
    ) THEN
        CREATE POLICY "Users can upload own profile image"
            ON storage.objects FOR INSERT
            TO authenticated
            WITH CHECK (
                bucket_id = 'profile-images'
                AND (storage.foldername(name))[1] = auth.uid()::text
            );
    END IF;
END $$;

-- Policy: Authenticated user can update only their own profile image
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
          AND tablename = 'objects' 
          AND policyname = 'Users can update own profile image'
    ) THEN
        CREATE POLICY "Users can update own profile image"
            ON storage.objects FOR UPDATE
            TO authenticated
            USING (
                bucket_id = 'profile-images'
                AND (storage.foldername(name))[1] = auth.uid()::text
            );
    END IF;
END $$;

-- Policy: Authenticated user can delete only their own profile image
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
          AND tablename = 'objects' 
          AND policyname = 'Users can delete own profile image'
    ) THEN
        CREATE POLICY "Users can delete own profile image"
            ON storage.objects FOR DELETE
            TO authenticated
            USING (
                bucket_id = 'profile-images'
                AND (storage.foldername(name))[1] = auth.uid()::text
            );
    END IF;
END $$;

-- 4. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
