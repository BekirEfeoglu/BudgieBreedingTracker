-- Close SECURITY DEFINER REST exposure flagged by Supabase linter (0028/0029).
--
-- Trigger helpers fn_audit_row_change / fn_audit_profile_role_change were
-- recreated in public with the default PUBLIC EXECUTE grant (so anon and
-- authenticated could call them over /rest/v1/rpc). Trigger functions must
-- never be REST-callable. Revoking EXECUTE does NOT affect trigger firing —
-- a trigger runs as the function owner regardless of the caller's grant.
--
-- increment_marketplace_listing_view granted EXECUTE to authenticated but left
-- the default PUBLIC grant in place, so anon could still call it. Keep it
-- callable by authenticated (the app uses it) and remove the anon path.
--
-- Idempotent: REVOKE is safe to re-run.

REVOKE ALL ON FUNCTION public.fn_audit_row_change() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_audit_profile_role_change() FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.increment_marketplace_listing_view(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.increment_marketplace_listing_view(uuid) TO authenticated;
