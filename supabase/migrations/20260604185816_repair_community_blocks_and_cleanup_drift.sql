-- =============================================================================
-- Repair community block persistence and cleanup function drift
-- =============================================================================
-- Live audit on 2026-06-04 showed:
--   1. public.community_blocks is referenced by app code and account deletion
--      RPCs but was never created by the migration chain.
--   2. cleanup_expired_* functions on the linked project still had an old
--      invalid RETURNING count(*) body despite the checked-in migration having
--      been corrected. Recreate them in a later migration to force convergence.
--
-- New public tables must be granted intentionally and protected by RLS before
-- they are reachable through the Supabase Data API.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.community_blocks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT community_blocks_no_self_block CHECK (user_id != blocked_user_id),
  CONSTRAINT community_blocks_unique_pair UNIQUE (user_id, blocked_user_id)
);

ALTER TABLE public.community_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_blocks FORCE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.community_blocks FROM PUBLIC, anon;
GRANT SELECT, INSERT, DELETE ON TABLE public.community_blocks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.community_blocks TO service_role;

DROP POLICY IF EXISTS "community_blocks_select" ON public.community_blocks;
CREATE POLICY "community_blocks_select"
  ON public.community_blocks
  FOR SELECT
  TO authenticated
  USING (
    (SELECT auth.uid()) = user_id
    OR (SELECT auth.uid()) = blocked_user_id
    OR (SELECT public.is_admin())
  );

DROP POLICY IF EXISTS "community_blocks_insert" ON public.community_blocks;
CREATE POLICY "community_blocks_insert"
  ON public.community_blocks
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) = user_id
    AND (SELECT auth.uid()) != blocked_user_id
  );

DROP POLICY IF EXISTS "community_blocks_delete" ON public.community_blocks;
CREATE POLICY "community_blocks_delete"
  ON public.community_blocks
  FOR DELETE
  TO authenticated
  USING (
    (SELECT auth.uid()) = user_id
    OR (SELECT public.is_admin())
  );

CREATE INDEX IF NOT EXISTS idx_community_blocks_user
  ON public.community_blocks (user_id);

CREATE INDEX IF NOT EXISTS idx_community_blocks_blocked_user
  ON public.community_blocks (blocked_user_id);

COMMENT ON TABLE public.community_blocks IS
  'Community block relationships. Users may create/delete their own outbound '
  'blocks; inbound visibility is allowed so account cleanup and reciprocal UI '
  'filters can see both sides under RLS.';

CREATE OR REPLACE FUNCTION public.cleanup_expired_rate_limits()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.notification_rate_limits
  WHERE window_start < now() - interval '24 hours';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.cleanup_expired_backups()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.backup_history
  WHERE expires_at IS NOT NULL
    AND expires_at < now()
    AND status = 'completed';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

REVOKE ALL ON FUNCTION public.cleanup_expired_rate_limits() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.cleanup_expired_backups() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_rate_limits() TO postgres, service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_backups() TO postgres, service_role;
