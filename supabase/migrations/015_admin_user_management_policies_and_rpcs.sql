-- ==============================================================================
-- Migration: 015_admin_user_management_policies_and_rpcs.sql
-- Description: Provide explicit Admin UPDATE and DELETE RLS policies on public.profiles
--              and robust security-definer RPC helpers for status and role management.
-- ==============================================================================

-- 1. Ensure RLS is enabled on public.profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. Explicit Admin RLS Policies on profiles
DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;
CREATE POLICY "Admins can update any profile"
    ON public.profiles FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins can delete any profile" ON public.profiles;
CREATE POLICY "Admins can delete any profile"
    ON public.profiles FOR DELETE TO authenticated
    USING (public.is_admin());

-- 3. Secure Admin Status Toggle RPC
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Secure Admin Role Update RPC
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5. Grant permissions to authenticated users
GRANT EXECUTE ON FUNCTION public.admin_toggle_user_status(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_user_role(UUID, TEXT) TO authenticated;

-- 6. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
