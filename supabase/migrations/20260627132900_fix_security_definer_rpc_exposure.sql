-- Fix Supabase Linter Warnings: anon_security_definer_function_executable & authenticated_security_definer_function_executable

-- Revoke public execution for trigger/internal functions to prevent direct API invocation
REVOKE ALL ON FUNCTION public.enforce_community_post_guards() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.prevent_self_community_report() FROM PUBLIC;

-- Revoke public (anon) execution from admin RPC and restrict it strictly to authenticated users.
-- The function internally enforces is_admin(), so authenticated users are safely guarded.
REVOKE ALL ON FUNCTION public.admin_get_user_aggregate_detail(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_get_user_aggregate_detail(uuid) TO authenticated;
