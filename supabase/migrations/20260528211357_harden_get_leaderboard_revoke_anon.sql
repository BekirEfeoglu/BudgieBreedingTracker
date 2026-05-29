-- Default PUBLIC EXECUTE grant lets anon call get_leaderboard via REST,
-- leaking display names to unauthenticated callers. Revoke from all roles
-- then grant only to authenticated (matches harden_security_definer_rpc_exposure).
REVOKE ALL ON FUNCTION public.get_leaderboard(integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_leaderboard(integer) TO authenticated;
