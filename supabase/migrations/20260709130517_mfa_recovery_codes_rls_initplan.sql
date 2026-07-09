-- Wrap auth.uid() in a subselect so the planner evaluates it once per query
-- (initplan) instead of re-evaluating per row — fixes the advisor
-- auth_rls_initplan warnings on mfa_recovery_codes (introduced by
-- 20260709115154, which used the bare auth.uid() form). Matches the
-- `(select auth.uid())` convention every other table already uses.

DROP POLICY IF EXISTS mfa_recovery_codes_own_select ON public.mfa_recovery_codes;
CREATE POLICY mfa_recovery_codes_own_select ON public.mfa_recovery_codes
  FOR SELECT USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS mfa_recovery_codes_own_insert ON public.mfa_recovery_codes;
CREATE POLICY mfa_recovery_codes_own_insert ON public.mfa_recovery_codes
  FOR INSERT WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS mfa_recovery_codes_own_delete ON public.mfa_recovery_codes;
CREATE POLICY mfa_recovery_codes_own_delete ON public.mfa_recovery_codes
  FOR DELETE USING (user_id = (select auth.uid()));
