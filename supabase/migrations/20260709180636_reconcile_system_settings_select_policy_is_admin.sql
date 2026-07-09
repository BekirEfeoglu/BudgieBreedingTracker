-- Reconcile the system_settings authenticated SELECT policy to reference
-- private.is_admin(), matching the deployed production definition.
--
-- Drift found during the 2026-07-09 audit (repo vs migration ledger): the
-- committed 20260430130000_consolidate_system_select_policies.sql created this
-- policy with public.is_admin(), but production applied private.is_admin(). No
-- later migration recreated the policy, so a fresh `db reset` would otherwise
-- end with public.is_admin() — which has a different body from private.is_admin()
-- (verified: normalized bodies differ), i.e. a real behavioral divergence, not
-- cosmetic. This forward migration is a no-op on prod (already private.is_admin)
-- and makes a fresh apply reproduce prod exactly. Idempotent + atomic.
DROP POLICY IF EXISTS "Users can view settings" ON public.system_settings;
CREATE POLICY "Users can view settings" ON public.system_settings
  FOR SELECT
  TO authenticated
  USING (is_public = true OR (SELECT private.is_admin()));
