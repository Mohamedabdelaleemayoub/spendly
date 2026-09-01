-- ==============================================================================
-- Migration: 016_fix_admin_user_management.sql
-- Description: Complete Production-Grade Admin User Management (Add User, Delete User,
--              Status Toggle & Role Update) via secure PostgreSQL RPCs.
-- ==============================================================================

-- 1. Ensure required cryptographic extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Foreign Key constraints safety on audit and created_by columns
-- Allow created_by to be SET NULL when an admin/creator is deleted so deletion never fails
DO $$
BEGIN
    -- employee_salary_advances.created_by
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'employee_salary_advances' AND column_name = 'created_by'
    ) THEN
        ALTER TABLE public.employee_salary_advances ALTER COLUMN created_by DROP NOT NULL;
    END IF;

    -- employee_allowance_transactions.created_by
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'employee_allowance_transactions' AND column_name = 'created_by'
    ) THEN
        ALTER TABLE public.employee_allowance_transactions ALTER COLUMN created_by DROP NOT NULL;
    END IF;

    -- employee_balance_transactions.created_by
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'employee_balance_transactions' AND column_name = 'created_by'
    ) THEN
        ALTER TABLE public.employee_balance_transactions ALTER COLUMN created_by DROP NOT NULL;
    END IF;
END $$;

-- 3. Secure Admin User Creation RPC
CREATE OR REPLACE FUNCTION public.admin_create_user(
    p_email TEXT,
    p_password TEXT,
    p_full_name TEXT,
    p_role TEXT DEFAULT 'employee'
)
RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_clean_email TEXT;
    v_clean_name TEXT;
    v_clean_role TEXT;
    v_now TIMESTAMPTZ;
    v_encrypted_pw TEXT;
    v_profile public.profiles%ROWTYPE;
BEGIN
    -- 1. Security Check: Caller must be an active admin
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'غير مصرح لك بإجراء هذه العملية. يلزم صلاحيات المشرف.';
    END IF;

    -- 2. Validate input parameters
    v_clean_email := LOWER(TRIM(COALESCE(p_email, '')));
    v_clean_name := TRIM(COALESCE(p_full_name, ''));
    v_clean_role := LOWER(TRIM(COALESCE(p_role, 'employee')));

    IF v_clean_email = '' OR p_password IS NULL OR v_clean_name = '' THEN
        RAISE EXCEPTION 'يرجى ملء جميع الحقول المطلوبة (الاسم، البريد الإلكتروني، كلمة المرور).';
    END IF;

    IF length(p_password) < 6 THEN
        RAISE EXCEPTION 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل.';
    END IF;

    IF position('@' in v_clean_email) = 0 OR position('.' in v_clean_email) = 0 THEN
        RAISE EXCEPTION 'البريد الإلكتروني المدخل غير صالح.';
    END IF;

    IF v_clean_role NOT IN ('admin', 'employee') THEN
        v_clean_role := 'employee';
    END IF;

    -- 3. Check for existing email in auth.users or public.profiles
    IF EXISTS (SELECT 1 FROM auth.users WHERE LOWER(email) = v_clean_email) OR
       EXISTS (SELECT 1 FROM public.profiles WHERE LOWER(email) = v_clean_email) THEN
        RAISE EXCEPTION 'البريد الإلكتروني مسجل مسبقاً لمستخدم آخر.';
    END IF;

    -- 4. Generate user ID and timestamps
    v_user_id := gen_random_uuid();
    v_now := timezone('utc'::text, now());
    v_encrypted_pw := crypt(p_password, gen_salt('bf'));

    -- 5. Insert directly into auth.users with verified status and metadata
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        role,
        aud,
        confirmation_token,
        is_super_admin
    ) VALUES (
        v_user_id,
        '00000000-0000-0000-0000-000000000000'::uuid,
        v_clean_email,
        v_encrypted_pw,
        v_now,
        jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
        jsonb_build_object('full_name', v_clean_name, 'name', v_clean_name),
        v_now,
        v_now,
        'authenticated',
        'authenticated',
        encode(gen_random_bytes(32), 'hex'),
        false
    );

    -- 6. Insert identity into auth.identities for GoTrue login lookup
    BEGIN
        INSERT INTO auth.identities (
            id,
            user_id,
            identity_data,
            provider,
            provider_id,
            last_sign_in_at,
            created_at,
            updated_at
        ) VALUES (
            v_user_id::text,
            v_user_id,
            jsonb_build_object('sub', v_user_id::text, 'email', v_clean_email),
            'email',
            v_clean_email,
            v_now,
            v_now,
            v_now
        );
    EXCEPTION WHEN OTHERS THEN
        -- Fallback if table constraints differ in local/hosted version
        NULL;
    END;

    -- 7. Ensure public.profiles record is created and set to active
    INSERT INTO public.profiles (
        id,
        full_name,
        email,
        role,
        status,
        salary_amount,
        salary_currency,
        created_at,
        updated_at
    ) VALUES (
        v_user_id,
        v_clean_name,
        v_clean_email,
        v_clean_role,
        'active',
        0.00,
        'EGP',
        v_now,
        v_now
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        role = EXCLUDED.role,
        status = 'active',
        updated_at = v_now
    RETURNING * INTO v_profile;

    -- 8. Return created profile summary
    RETURN json_build_object(
        'success', true,
        'id', v_profile.id,
        'user', json_build_object(
            'id', v_profile.id,
            'email', v_profile.email,
            'full_name', v_profile.full_name,
            'name', v_profile.full_name,
            'role', v_profile.role,
            'status', v_profile.status,
            'salary_amount', COALESCE(v_profile.salary_amount, 0.00),
            'salary_currency', COALESCE(v_profile.salary_currency, 'EGP'),
            'created_at', v_profile.created_at,
            'updated_at', v_profile.updated_at
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth, extensions;

-- 4. Secure Admin User Deletion RPC
CREATE OR REPLACE FUNCTION public.admin_delete_user(
    p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_target_role TEXT;
    v_target_name TEXT;
    v_active_admins_count INT;
BEGIN
    -- 1. Security Check: Caller must be an active admin
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'غير مصرح لك بإجراء هذه العملية. يلزم صلاحيات المشرف.';
    END IF;

    -- 2. Prevent self-deletion
    IF p_user_id = auth.uid() THEN
        RAISE EXCEPTION 'لا يمكنك حذف حسابك الحالي.';
    END IF;

    -- 3. Check target user existence and role
    SELECT role, full_name INTO v_target_role, v_target_name
    FROM public.profiles 
    WHERE id = p_user_id;

    IF v_target_role IS NULL THEN
        -- If profile not found, check auth.users directly
        IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
            RAISE EXCEPTION 'لم يتم العثور على المستخدم المطلوب.';
        END IF;
    END IF;

    -- 4. Prevent deleting the last remaining administrator
    IF v_target_role = 'admin' THEN
        SELECT count_active_admins() INTO v_active_admins_count;
        IF v_active_admins_count <= 1 THEN
            RAISE EXCEPTION 'لا يمكن حذف آخر مسؤول متبقي في النظام.';
        END IF;
    END IF;

    -- 5. Safely clean up dependent creator references to avoid FK blocking
    UPDATE public.employee_salary_advances 
    SET created_by = auth.uid() 
    WHERE created_by = p_user_id;

    UPDATE public.employee_allowance_transactions 
    SET created_by = auth.uid() 
    WHERE created_by = p_user_id;

    UPDATE public.employee_balance_transactions 
    SET created_by = auth.uid() 
    WHERE created_by = p_user_id;

    UPDATE public.app_settings 
    SET updated_by = auth.uid() 
    WHERE updated_by = p_user_id;

    UPDATE public.audit_logs 
    SET user_id = NULL 
    WHERE user_id = p_user_id;

    -- 6. Delete from auth.identities
    BEGIN
        DELETE FROM auth.identities WHERE user_id = p_user_id;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;

    -- 7. Delete user from auth.users (cascades to public.profiles and related records)
    DELETE FROM auth.users WHERE id = p_user_id;

    -- 8. Explicit cleanup of profiles if profile wasn't linked to auth
    DELETE FROM public.profiles WHERE id = p_user_id;

    RETURN json_build_object(
        'success', true,
        'user_id', p_user_id,
        'message', 'تم حذف حساب المستخدم بنجاح.'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth, extensions;

-- 5. Secure Admin Status Toggle RPC (Enhanced with pending/rejected/inactive/active)
CREATE OR REPLACE FUNCTION public.admin_toggle_user_status(
    p_user_id UUID,
    p_status TEXT
)
RETURNS JSON AS $$
DECLARE
    v_target_role TEXT;
    v_active_admins_count INT;
    v_updated_profile public.profiles%ROWTYPE;
BEGIN
    -- Verify caller is an active admin
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'غير مصرح لك بإجراء هذه العملية. يلزم صلاحيات المشرف.';
    END IF;

    -- Validate status value
    IF p_status NOT IN ('active', 'inactive', 'pending', 'rejected') THEN
        RAISE EXCEPTION 'قيمة الحالة غير صالحة (active, inactive, pending, rejected).';
    END IF;

    -- If deactivating or rejecting, prevent self-deactivation
    IF p_status IN ('inactive', 'rejected') AND p_user_id = auth.uid() THEN
        RAISE EXCEPTION 'لا يمكنك تعطيل أو رفض حسابك الحالي.';
    END IF;

    -- Check target user role
    SELECT role INTO v_target_role FROM public.profiles WHERE id = p_user_id;
    IF v_target_role = 'admin' AND p_status IN ('inactive', 'rejected') THEN
        SELECT count_active_admins() INTO v_active_admins_count;
        IF v_active_admins_count <= 1 THEN
            RAISE EXCEPTION 'لا يمكن تعطيل آخر مسؤول نشط في النظام.';
        END IF;
    END IF;

    -- Update profile status
    UPDATE public.profiles
    SET status = p_status,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_user_id
    RETURNING * INTO v_updated_profile;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'لم يتم العثور على المستخدم المطلوب.';
    END IF;

    RETURN json_build_object(
        'success', true,
        'user_id', v_updated_profile.id,
        'status', v_updated_profile.status
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth, extensions;

-- 6. Secure Admin Role Update RPC
CREATE OR REPLACE FUNCTION public.admin_update_user_role(
    p_user_id UUID,
    p_role TEXT
)
RETURNS JSON AS $$
DECLARE
    v_target_old_role TEXT;
    v_active_admins_count INT;
    v_updated_profile public.profiles%ROWTYPE;
BEGIN
    -- Verify caller is an active admin
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'غير مصرح لك بإجراء هذه العملية. يلزم صلاحيات المشرف.';
    END IF;

    -- Validate role value
    IF p_role NOT IN ('admin', 'employee') THEN
        RAISE EXCEPTION 'قيمة الصلاحية غير صالحة (admin, employee).';
    END IF;

    -- If demoting an admin to employee, prevent demoting the last active admin
    SELECT role INTO v_target_old_role FROM public.profiles WHERE id = p_user_id;
    IF v_target_old_role = 'admin' AND p_role = 'employee' THEN
        SELECT count_active_admins() INTO v_active_admins_count;
        IF v_active_admins_count <= 1 THEN
            RAISE EXCEPTION 'لا يمكن تخفيض صلاحية آخر مسؤول متبقي في النظام.';
        END IF;
    END IF;

    -- Update profile role
    UPDATE public.profiles
    SET role = p_role,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_user_id
    RETURNING * INTO v_updated_profile;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'لم يتم العثور على المستخدم المطلوب.';
    END IF;

    RETURN json_build_object(
        'success', true,
        'user_id', v_updated_profile.id,
        'role', v_updated_profile.role
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth, extensions;

-- 7. Grant permissions to authenticated users
GRANT EXECUTE ON FUNCTION public.admin_create_user(TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_user(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_toggle_user_status(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_user_role(UUID, TEXT) TO authenticated;

-- 8. Explicit Admin RLS Policies on profiles (Ensure UPDATE and DELETE are permitted)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;
CREATE POLICY "Admins can update any profile"
    ON public.profiles FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins can delete any profile" ON public.profiles;
CREATE POLICY "Admins can delete any profile"
    ON public.profiles FOR DELETE TO authenticated
    USING (public.is_admin());

-- 9. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
