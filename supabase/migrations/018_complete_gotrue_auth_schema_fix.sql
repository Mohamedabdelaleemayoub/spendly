-- ==============================================================================
-- Spendly / Egypt Edu Gate - Migration 018: Complete GoTrue Auth Schema Compatibility
-- Purpose:
-- Fix ALL GoTrue schema scanning requirements in auth.users and auth.identities
-- to eliminate the "Database error querying schema" (HTTP 500) error on login.
-- ==============================================================================

-- ── 1. Update public.admin_create_user RPC with Complete Non-Null Fields ─────
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
    v_encrypted_pw := extensions.crypt(p_password, extensions.gen_salt('bf', 10));

    -- 5. Insert into auth.users with ALL GoTrue non-null scan fields populated
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
        recovery_token,
        email_change_token_new,
        email_change,
        phone_change,
        phone_change_token,
        email_change_token_current,
        reauthentication_token,
        email_change_confirm_status,
        is_super_admin,
        is_sso_user,
        is_anonymous
    ) VALUES (
        v_user_id,
        '00000000-0000-0000-0000-000000000000'::uuid,
        v_clean_email,
        v_encrypted_pw,
        v_now,
        jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
        jsonb_build_object(
            'full_name', v_clean_name,
            'name', v_clean_name,
            'email', v_clean_email,
            'email_verified', true,
            'phone_verified', false,
            'sub', v_user_id::text
        ),
        v_now,
        v_now,
        'authenticated',
        'authenticated',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        0,
        false,
        false,
        false
    );

    -- 6. Insert identity into auth.identities
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
            v_user_id,
            v_user_id,
            jsonb_build_object(
                'sub', v_user_id::text,
                'email', v_clean_email,
                'email_verified', true,
                'phone_verified', false
            ),
            'email',
            v_user_id::text,
            v_now,
            v_now,
            v_now
        )
        ON CONFLICT (provider, provider_id) DO UPDATE SET
            identity_data = EXCLUDED.identity_data,
            updated_at = EXCLUDED.updated_at;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;

    -- 7. Ensure public.profiles record is created and active
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

-- ── 2. Sanitize and Repair All Existing auth.users Records ────────────────────
UPDATE auth.users
SET 
    instance_id = COALESCE(instance_id, '00000000-0000-0000-0000-000000000000'::uuid),
    aud = 'authenticated',
    role = 'authenticated',
    confirmation_token = COALESCE(confirmation_token, ''),
    recovery_token = COALESCE(recovery_token, ''),
    email_change_token_new = COALESCE(email_change_token_new, ''),
    email_change = COALESCE(email_change, ''),
    phone_change = COALESCE(phone_change, ''),
    phone_change_token = COALESCE(phone_change_token, ''),
    email_change_token_current = COALESCE(email_change_token_current, ''),
    reauthentication_token = COALESCE(reauthentication_token, ''),
    email_change_confirm_status = COALESCE(email_change_confirm_status, 0),
    is_super_admin = COALESCE(is_super_admin, false),
    is_sso_user = COALESCE(is_sso_user, false),
    is_anonymous = COALESCE(is_anonymous, false),
    raw_app_meta_data = COALESCE(raw_app_meta_data, jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email'))),
    raw_user_meta_data = jsonb_build_object(
        'sub', id::text,
        'email', lower(email),
        'email_verified', true,
        'phone_verified', false,
        'full_name', COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', split_part(email, '@', 1)),
        'name', COALESCE(raw_user_meta_data->>'name', raw_user_meta_data->>'full_name', split_part(email, '@', 1))
    ),
    email_confirmed_at = COALESCE(email_confirmed_at, timezone('utc'::text, now())),
    updated_at = timezone('utc'::text, now())
WHERE email IS NOT NULL;

-- ── 3. Sanitize and Repair All auth.identities Records ────────────────────────
DELETE FROM auth.identities WHERE provider = 'email' AND provider_id <> user_id::text;

INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
)
SELECT 
    u.id,
    u.id,
    jsonb_build_object(
        'sub', u.id::text,
        'email', lower(u.email),
        'email_verified', true,
        'phone_verified', false
    ),
    'email',
    u.id::text,
    u.last_sign_in_at,
    u.created_at,
    u.updated_at
FROM auth.users u
WHERE u.email IS NOT NULL
ON CONFLICT (provider, provider_id) DO UPDATE SET
    identity_data = EXCLUDED.identity_data,
    updated_at = EXCLUDED.updated_at;

-- ── 4. Set Password Reset / Resync Helper for Existing User ──────────────────
CREATE OR REPLACE FUNCTION public.admin_reset_user_password(
    p_email TEXT,
    p_new_password TEXT
)
RETURNS JSON AS $$
DECLARE
    v_clean_email TEXT;
    v_encrypted_pw TEXT;
    v_user_id UUID;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'غير مصرح لك بإجراء هذه العملية. يلزم صلاحيات المشرف.';
    END IF;

    v_clean_email := LOWER(TRIM(COALESCE(p_email, '')));
    IF v_clean_email = '' OR p_new_password IS NULL OR length(p_new_password) < 6 THEN
        RAISE EXCEPTION 'يرجى إدخال بريد إلكتروني صالح وكلمة مرور لا تقل عن 6 أحرف.';
    END IF;

    SELECT id INTO v_user_id FROM auth.users WHERE LOWER(email) = v_clean_email;
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'لم يتم العثور على المستخدم المطلوب.';
    END IF;

    v_encrypted_pw := extensions.crypt(p_new_password, extensions.gen_salt('bf', 10));

    UPDATE auth.users
    SET encrypted_password = v_encrypted_pw,
        updated_at = timezone('utc'::text, now())
    WHERE id = v_user_id;

    RETURN json_build_object('success', true, 'message', 'تم تحديث كلمة المرور بنجاح.');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth, extensions;

GRANT EXECUTE ON FUNCTION public.admin_create_user(TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_reset_user_password(TEXT, TEXT) TO authenticated;
NOTIFY pgrst, 'reload schema';
