-- Put get_leaderboard + increment_marketplace_listing_view behind public
-- SECURITY INVOKER wrappers over private SECURITY DEFINER implementations,
-- matching harden_security_definer_rpc_exposure. Clears the last two
-- 0029 advisor warnings: the public functions become INVOKER (not flagged),
-- the privileged DEFINER bodies live in `private` (not a PostgREST-exposed API
-- schema), and the app keeps calling the same public.* signatures.
--
-- Idempotent: the SET SCHEMA move runs only while the public function is still
-- the SECURITY DEFINER original; a rerun sees the INVOKER wrapper and skips.

-- 1. get_leaderboard ---------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'get_leaderboard' AND p.prosecdef
  ) THEN
    ALTER FUNCTION public.get_leaderboard(integer) SET SCHEMA private;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.get_leaderboard(p_limit integer DEFAULT 100)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  total_xp integer,
  level integer,
  current_level_xp integer,
  next_level_xp integer,
  title text,
  updated_at timestamptz,
  display_name text
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT * FROM private.get_leaderboard(p_limit);
$$;

-- 2. increment_marketplace_listing_view -------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'increment_marketplace_listing_view' AND p.prosecdef
  ) THEN
    ALTER FUNCTION public.increment_marketplace_listing_view(uuid) SET SCHEMA private;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.increment_marketplace_listing_view(p_id uuid)
RETURNS void
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.increment_marketplace_listing_view(p_id);
$$;

-- 3. Grants ------------------------------------------------------------------
-- Public wrappers: authenticated only (anon already revoked in 20260529130000).
REVOKE ALL ON FUNCTION public.get_leaderboard(integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_leaderboard(integer) TO authenticated;
REVOKE ALL ON FUNCTION public.increment_marketplace_listing_view(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.increment_marketplace_listing_view(uuid) TO authenticated;

-- Private implementations: reachable only through the wrappers.
REVOKE ALL ON FUNCTION private.get_leaderboard(integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.get_leaderboard(integer) TO authenticated, service_role;
REVOKE ALL ON FUNCTION private.increment_marketplace_listing_view(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.increment_marketplace_listing_view(uuid) TO authenticated, service_role;
