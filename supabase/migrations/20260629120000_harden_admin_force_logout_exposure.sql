-- Harden admin_force_logout SECURITY DEFINER exposure (Supabase linter 0029).
-- admin_force_logout (20260627134000) was added in public as SECURITY DEFINER
-- and granted to authenticated, which the linter flags even though the body
-- guards on public.is_admin(). Bring it into the same posture as
-- 20260501115000: the privileged implementation lives in the private schema
-- (not listed in supabase/config.toml exposed API schemas) and public keeps a
-- thin SECURITY INVOKER wrapper. The public name + signature are unchanged, so
-- the existing client rpc('admin_force_logout', {target_user_id}) keeps working.

-- 1. Move the privileged SECURITY DEFINER implementation out of the exposed
--    public API schema into private. Idempotent: only acts while the function
--    is still a SECURITY DEFINER function in public.
DO $$
DECLARE
  fn record;
BEGIN
  FOR fn IN
    SELECT pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'admin_force_logout'
      AND p.prosecdef
  LOOP
    EXECUTE format(
      'ALTER FUNCTION public.admin_force_logout(%s) SET SCHEMA private',
      fn.args
    );
  END LOOP;
END $$;

-- 2. Public SECURITY INVOKER wrapper delegates to the private implementation.
CREATE OR REPLACE FUNCTION public.admin_force_logout(target_user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_force_logout(target_user_id);
$$;

-- 3. Keep both wrapper and private impl callable only by signed-in/service
--    callers (matches 20260501115000 grant posture).
DO $$
DECLARE
  fn record;
BEGIN
  FOR fn IN
    SELECT n.nspname, pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('public', 'private')
      AND p.proname = 'admin_force_logout'
  LOOP
    EXECUTE format(
      'REVOKE ALL ON FUNCTION %I.admin_force_logout(%s) FROM PUBLIC, anon, authenticated',
      fn.nspname,
      fn.args
    );
    EXECUTE format(
      'GRANT EXECUTE ON FUNCTION %I.admin_force_logout(%s) TO authenticated, service_role',
      fn.nspname,
      fn.args
    );
  END LOOP;
END $$;
