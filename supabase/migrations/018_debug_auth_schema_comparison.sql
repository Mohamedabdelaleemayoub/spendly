-- Migration 018: Debug Auth Schema Comparison
CREATE OR REPLACE FUNCTION public.debug_inspect_auth_users()
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'users', (
            SELECT json_agg(row_to_json(u))
            FROM (
                SELECT id, email, role, aud, confirmation_token, email_confirmed_at, 
                       (encrypted_password IS NOT NULL) as has_password,
                       raw_app_meta_data, raw_user_meta_data,
                       is_super_admin, is_sso_user, is_anonymous,
                       created_at, updated_at
                FROM auth.users
                WHERE email LIKE '%fayoum.edu.eg' OR email LIKE 'diag_test%'
            ) u
        ),
        'identities', (
            SELECT json_agg(row_to_json(i))
            FROM (
                SELECT id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
                FROM auth.identities
                WHERE user_id IN (
                    SELECT id FROM auth.users WHERE email LIKE '%fayoum.edu.eg' OR email LIKE 'diag_test%'
                )
            ) i
        )
    ) INTO v_result;
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

GRANT EXECUTE ON FUNCTION public.debug_inspect_auth_users() TO anon, authenticated;
NOTIFY pgrst, 'reload schema';
