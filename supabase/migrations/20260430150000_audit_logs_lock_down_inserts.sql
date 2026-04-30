-- =============================================================================
-- audit_logs: lock down INSERT to system writers only
-- =============================================================================
-- Problem (audit finding):
--   public.audit_logs has carried an "insert own / admin" RLS policy
--   (see 20260223154910_consolidate_audit_logs_rls_policies.sql, plus the
--   original 20260218073830_create_audit_logs_table.sql definition). Combined
--   with the authenticated-INSERT GRANT, any signed-in client could write
--   arbitrary action / old_data / new_data JSONB into the audit table. That
--   undermines the entire purpose of audit_logs (forensic immutability) and
--   lets a malicious user spoof admin-looking entries.
--
--   The actual writers we want are SECURITY DEFINER trigger functions
--   (fn_audit_row_change, fn_audit_profile_role_change, handle_new_user, etc.)
--   plus the service_role used by Edge Functions. Both bypass RLS, so the
--   client-facing INSERT policy and INSERT GRANT are not needed.
--
-- Effect:
--   - DROPs all client-visible INSERT policies on audit_logs.
--   - REVOKEs the INSERT grant from the `authenticated` and `anon` roles.
--   - SELECT/UPDATE/DELETE policies (admin-only) are unchanged.
--   - SECURITY DEFINER triggers continue to write because they execute as the
--     function owner (typically `postgres`) which bypasses RLS unless FORCE RLS
--     is set on the table.
--
-- Idempotent.
-- =============================================================================

DROP POLICY IF EXISTS "audit_logs: insert"      ON public.audit_logs;
DROP POLICY IF EXISTS "audit_logs: insert own"  ON public.audit_logs;
DROP POLICY IF EXISTS "audit_logs: admin all"   ON public.audit_logs;

REVOKE INSERT ON public.audit_logs FROM authenticated;
REVOKE INSERT ON public.audit_logs FROM anon;
REVOKE ALL    ON public.audit_logs FROM anon;

-- Recreate the admin-only ALL policy explicitly so the audit panel keeps
-- working (the previous migration broke it into per-command policies; we keep
-- those for SELECT/UPDATE/DELETE and just leave INSERT unowned by clients).
-- No new policies needed — admin SELECT already exists from
-- 20260223154910_consolidate_audit_logs_rls_policies.sql.

COMMENT ON TABLE public.audit_logs IS
  'Append-only audit trail. Writes only by SECURITY DEFINER trigger functions '
  '(fn_audit_row_change, fn_audit_profile_role_change, handle_new_user, …) or '
  'by service_role. Authenticated clients have no INSERT access by design.';
