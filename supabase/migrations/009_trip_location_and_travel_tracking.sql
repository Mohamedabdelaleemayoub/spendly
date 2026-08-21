-- ============================================================================
-- Migration 009: Trip Location & Out-of-Cairo Travel Tracking
-- Purpose:
-- 1. Add trip_location_type ('cairo', 'outside_cairo') to public.expenses
-- 2. Add governorate column with integrity validation to public.expenses
-- 3. Safely backfill existing expenses to default ('cairo', 'cairo')
-- 4. Create performance indexes for location & governorate queries
-- 5. Seed default travel_bonus_settings into public.app_settings
-- ============================================================================

-- 1. Add trip_location_type column to public.expenses if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'expenses' AND column_name = 'trip_location_type'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN trip_location_type TEXT NOT NULL DEFAULT 'cairo';
    END IF;
END $$;

ALTER TABLE public.expenses DROP CONSTRAINT IF EXISTS expenses_trip_location_type_check;
ALTER TABLE public.expenses ADD CONSTRAINT expenses_trip_location_type_check 
    CHECK (trip_location_type IN ('cairo', 'outside_cairo'));

-- 2. Add governorate column to public.expenses if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'expenses' AND column_name = 'governorate'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN governorate TEXT NOT NULL DEFAULT 'cairo';
    END IF;
END $$;

-- 3. Backfill existing null / legacy rows safely before adding check constraint
UPDATE public.expenses 
SET trip_location_type = 'cairo', governorate = 'cairo' 
WHERE trip_location_type IS NULL OR governorate IS NULL;

-- 4. Enforce Location & Governorate consistency rule
-- If cairo => governorate must be 'cairo'
-- If outside_cairo => governorate must be non-null and NOT 'cairo'
ALTER TABLE public.expenses DROP CONSTRAINT IF EXISTS expenses_governorate_consistency_check;
ALTER TABLE public.expenses ADD CONSTRAINT expenses_governorate_consistency_check 
    CHECK (
        (trip_location_type = 'cairo' AND governorate = 'cairo')
        OR
        (trip_location_type = 'outside_cairo' AND governorate IS NOT NULL AND governorate <> 'cairo')
    );

-- 5. Create Performance Indexes
CREATE INDEX IF NOT EXISTS idx_expenses_user_trip_location ON public.expenses(user_id, trip_location_type);
CREATE INDEX IF NOT EXISTS idx_expenses_trip_gov ON public.expenses(trip_location_type, governorate);

-- 6. Ensure public.app_settings table exists (matches Migration 006 & Flutter contract)
CREATE TABLE IF NOT EXISTS public.app_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL
);

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

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

-- Seed default require_admin_approval if not present
INSERT INTO public.app_settings (key, value, description)
VALUES ('require_admin_approval', '{"enabled": false}'::jsonb, 'Require admin approval before new users can access the application')
ON CONFLICT (key) DO NOTHING;

-- Seed default travel_bonus_settings in public.app_settings
INSERT INTO public.app_settings (key, value, description)
VALUES (
    'travel_bonus_settings',
    jsonb_build_object(
        'enabled', false,
        'bonus_per_trip', 100.0,
        'currency', 'EGP'
    ),
    'Configurable travel bonus settings for outside-Cairo employee trips'
)
ON CONFLICT (key) DO NOTHING;

-- 7. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
