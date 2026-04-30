-- =============================================================================
-- mfa_lockouts: lock down INSERT/UPDATE/DELETE to service_role only
-- =============================================================================
-- CRITICAL security finding (Postgres best-practices audit, 2026-05-01):
--
--   public.mfa_lockouts carries client-facing INSERT/UPDATE/DELETE policies
--   from 20260325175000_create_mfa_lockouts_table.sql (later wrapped in
--   20260329150000_fix_rls_performance_and_gaps.sql for InitPlan caching, but
--   semantics unchanged):
--
--     "Users can insert own mfa_lockout"  FOR INSERT  WITH CHECK (uid = user_id)
--     "Users can update own mfa_lockout"  FOR UPDATE  USING (uid = user_id)
--     "Users can delete own mfa_lockout"  FOR DELETE  USING (uid = user_id)
--
--   Combined with the authenticated-INSERT/UPDATE/DELETE GRANTs that come from
--   the default `authenticated` role, this means a signed-in user can:
--
--     1. UPDATE their own row to set failed_attempts = 0,
--        locked_until = NULL, lockout_count = 0
--        — completely bypassing MFA brute-force protection
--     2. DELETE their lockout row entirely (same effect)
--     3. Re-INSERT a fresh row with zeroed counters (after delete)
--
--   The intended writers are the `mfa-lockout` Edge Function (which uses
--   `createSupabaseAdmin()` → service_role, bypasses RLS) and the
--   trigger-driven UPDATEs from auth events. Neither needs the client-facing
--   write policies. Same pattern as audit_logs lockdown (20260430150000).
--
-- Effect:
--   - DROP the INSERT, UPDATE, DELETE policies on public.mfa_lockouts
--   - REVOKE INSERT, UPDATE, DELETE from `authenticated` and `anon`
--   - SELECT policy remains so the client can render "you're locked out"
--   - service_role and SECURITY DEFINER triggers continue to write
--
-- Idempotent.
-- =============================================================================

DROP POLICY IF EXISTS "Users can insert own mfa_lockout" ON public.mfa_lockouts;
DROP POLICY IF EXISTS "Users can update own mfa_lockout" ON public.mfa_lockouts;
DROP POLICY IF EXISTS "Users can delete own mfa_lockout" ON public.mfa_lockouts;

REVOKE INSERT, UPDATE, DELETE ON public.mfa_lockouts FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.mfa_lockouts FROM anon;
REVOKE ALL                    ON public.mfa_lockouts FROM anon;

-- Re-affirm the SELECT policy with the wrapped (SELECT auth.uid()) pattern.
-- Already present from 20260329150000 but we make it explicit here so the
-- file fully describes the intended end state.
DROP POLICY IF EXISTS "Users can read own mfa_lockout" ON public.mfa_lockouts;
CREATE POLICY "Users can read own mfa_lockout"
  ON public.mfa_lockouts FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

COMMENT ON TABLE public.mfa_lockouts IS
  'MFA brute-force protection state. Writes only by the mfa-lockout Edge '
  'Function via service_role. Authenticated clients have SELECT-only access '
  'so they can render lockout state in the UI but cannot reset it.';
