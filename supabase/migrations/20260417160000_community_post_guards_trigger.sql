-- =============================================================================
-- Migration: Enforce community post guards server-side via trigger
-- Date: 2026-04-17
-- Problem:
--   check_community_post_allowed() is invoked by the mobile client before
--   inserting into community_posts, but the INSERT RLS policy only verifies
--   ownership (user_id = auth.uid()). A caller speaking to the PostgREST
--   API directly can bypass the client-side guard and spam posts.
-- Fix:
--   Add a BEFORE INSERT trigger that re-evaluates the same guard server-
--   side and raises on denial. The trigger bypasses admins/founders so
--   system-authored guide posts are not rate-limited.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.enforce_community_post_guards()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_result jsonb;
  v_reason text;
BEGIN
  -- Admins and founders are exempt from rate limits, account-age gates,
  -- and dedup so they can publish guides / announcements freely.
  IF public.is_admin() THEN
    RETURN NEW;
  END IF;

  v_result := public.check_community_post_allowed(NEW.content_hash);

  IF (v_result->>'allowed')::boolean IS DISTINCT FROM true THEN
    v_reason := coalesce(v_result->>'reason', 'denied');
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'community_post_guard_denied',
      DETAIL  = v_reason,
      HINT    = 'Matches client-side check_community_post_allowed reason codes';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_community_post_guards
  ON public.community_posts;

CREATE TRIGGER trg_enforce_community_post_guards
  BEFORE INSERT ON public.community_posts
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_community_post_guards();

COMMENT ON FUNCTION public.enforce_community_post_guards() IS
  'BEFORE INSERT guard on community_posts. Re-evaluates '
  'check_community_post_allowed() server-side so direct PostgREST callers '
  'cannot bypass the client-side pre-check. Admins/founders are exempt.';
