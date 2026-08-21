-- ==============================================================================
-- Spendly - Migration 013: Audit Logs & Production Security
-- Purpose:
-- 1. Create audit_logs table for comprehensive financial & administrative tracking
-- 2. Strict Row Level Security (RLS) policies:
--    - Admins: SELECT all audit logs
--    - Authenticated: INSERT own audit logs
--    - Immutability: UPDATE and DELETE are strictly disabled
-- 3. High-performance indexes for entity and time-series audit queries
-- ==============================================================================

-- ── 1. Create audit_logs Table ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NULL,
    old_value JSONB NULL,
    new_value JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Indexes for performance and filtering
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at 
    ON public.audit_logs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entity 
    ON public.audit_logs(entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id 
    ON public.audit_logs(user_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_action 
    ON public.audit_logs(action);

-- ── 2. Strict Row Level Security (RLS) ───────────────────────────────────────
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view audit logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Authenticated users can insert audit logs" ON public.audit_logs;
DROP POLICY IF EXISTS "No one can update audit logs" ON public.audit_logs;
DROP POLICY IF EXISTS "No one can delete audit logs" ON public.audit_logs;

-- SELECT: Only administrators can view audit logs
CREATE POLICY "Admins can view audit logs"
    ON public.audit_logs FOR SELECT TO authenticated
    USING (public.is_admin());

-- INSERT: Authenticated users can log operations
CREATE POLICY "Authenticated users can insert audit logs"
    ON public.audit_logs FOR INSERT TO authenticated
    WITH CHECK (auth.uid() IS NOT NULL);

-- UPDATE: Audit records are strictly immutable
CREATE POLICY "No one can update audit logs"
    ON public.audit_logs FOR UPDATE TO authenticated
    USING (false);

-- DELETE: Audit records cannot be deleted
CREATE POLICY "No one can delete audit logs"
    ON public.audit_logs FOR DELETE TO authenticated
    USING (false);

-- ── 3. Reload PostgREST Schema Cache ─────────────────────────────────────────
NOTIFY pgrst, 'reload schema';
