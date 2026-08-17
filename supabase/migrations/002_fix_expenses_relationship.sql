-- ==============================================================================
-- Spendly - Migration 002: Fix Foreign Key Relationship for PostgREST
-- Purpose: Ensure public.expenses.user_id explicitly references public.profiles(id)
--          so PostgREST schema cache can resolve resource embedding:
--          `profiles:user_id(id, full_name, email, role)`
-- ==============================================================================

-- 1. Ensure all auth.users have a corresponding public.profiles entry
INSERT INTO public.profiles (id, full_name, email, role)
SELECT 
    u.id,
    COALESCE(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', split_part(u.email, '@', 1), 'مستخدم'),
    u.email,
    'employee'
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- 2. Clean up any orphan expenses whose user_id is not in auth.users
-- (Safety check: If an expense has a user_id with no profile and no auth user, log/delete or handle)
DO $$
DECLARE
    orphan_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO orphan_count
    FROM public.expenses e
    LEFT JOIN public.profiles p ON p.id = e.user_id
    WHERE p.id IS NULL;

    IF orphan_count > 0 THEN
        RAISE NOTICE 'Found % orphan expenses with no profile. Inserting placeholder profiles...', orphan_count;
        INSERT INTO public.profiles (id, full_name, role)
        SELECT DISTINCT e.user_id, 'مستخدم محذوف', 'employee'
        FROM public.expenses e
        LEFT JOIN public.profiles p ON p.id = e.user_id
        WHERE p.id IS NULL
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

-- 3. Drop all existing foreign key constraints on expenses.user_id
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT tc.constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        WHERE tc.table_schema = 'public'
          AND tc.table_name = 'expenses'
          AND tc.constraint_type = 'FOREIGN KEY'
          AND kcu.column_name = 'user_id'
    ) LOOP
        EXECUTE 'ALTER TABLE public.expenses DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
        RAISE NOTICE 'Dropped old constraint: %', r.constraint_name;
    END LOOP;
END $$;

-- 4. Re-create the explicit foreign key: expenses.user_id -> public.profiles.id
ALTER TABLE public.expenses
    ADD CONSTRAINT expenses_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.profiles(id)
    ON DELETE CASCADE;

-- 5. Drop and re-create the category foreign key: expenses.category_id -> public.categories.id
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT tc.constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        WHERE tc.table_schema = 'public'
          AND tc.table_name = 'expenses'
          AND tc.constraint_type = 'FOREIGN KEY'
          AND kcu.column_name = 'category_id'
    ) LOOP
        EXECUTE 'ALTER TABLE public.expenses DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
        RAISE NOTICE 'Dropped old constraint: %', r.constraint_name;
    END LOOP;
END $$;

ALTER TABLE public.expenses
    ADD CONSTRAINT expenses_category_id_fkey
    FOREIGN KEY (category_id)
    REFERENCES public.categories(id)
    ON DELETE SET NULL;

-- 6. Ensure indexes exist for performant joins
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON public.expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses(expense_date DESC);

-- 7. Grant necessary permissions to PostgREST API roles
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

-- 8. Reload PostgREST schema cache immediately
NOTIFY pgrst, 'reload schema';
