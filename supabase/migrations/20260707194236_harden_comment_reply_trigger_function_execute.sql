-- Harden trigger-only SECURITY DEFINER functions from the threaded comments
-- migration. They are invoked by table triggers, not by client RPC calls.
-- Supabase advisor 0028/0029 flags public SECURITY DEFINER functions that
-- anon/authenticated can execute through /rest/v1/rpc/<function>.

DO $$
DECLARE
  fn record;
BEGIN
  FOR fn IN
    SELECT
      p.proname,
      pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN (
        'validate_community_comment_parent',
        'update_comment_reply_count'
      )
      AND p.prosecdef
  LOOP
    EXECUTE format(
      'REVOKE ALL ON FUNCTION public.%I(%s) FROM PUBLIC, anon, authenticated',
      fn.proname,
      fn.args
    );

    EXECUTE format(
      'GRANT EXECUTE ON FUNCTION public.%I(%s) TO postgres, service_role',
      fn.proname,
      fn.args
    );
  END LOOP;
END $$;

COMMENT ON FUNCTION public.validate_community_comment_parent() IS
  'Trigger-only parent validation for threaded community comments. Client roles do not have EXECUTE.';

COMMENT ON FUNCTION public.update_comment_reply_count() IS
  'Trigger-only direct reply counter maintenance for community comments. Client roles do not have EXECUTE.';
