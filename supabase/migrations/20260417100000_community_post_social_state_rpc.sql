-- ============================================================================
-- Community post social state RPC
-- ============================================================================
-- Combines the per-user `liked` and `bookmarked` lookups for a batch of post
-- IDs into a single round-trip. Previously the client issued two parallel
-- PostgREST queries against `community_likes` and `community_bookmarks`; this
-- RPC returns both in one response.
--
-- Security: SECURITY INVOKER — the function respects existing RLS policies on
-- community_likes and community_bookmarks, so users only see their own rows.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.fetch_user_post_social_state(
  p_user_id uuid,
  p_post_ids uuid[]
)
RETURNS TABLE (
  post_id uuid,
  is_liked boolean,
  is_bookmarked boolean
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    pid AS post_id,
    EXISTS(
      SELECT 1 FROM community_likes cl
      WHERE cl.user_id = p_user_id
        AND cl.post_id = pid
    ) AS is_liked,
    EXISTS(
      SELECT 1 FROM community_bookmarks cb
      WHERE cb.user_id = p_user_id
        AND cb.post_id = pid
    ) AS is_bookmarked
  FROM unnest(p_post_ids) AS pid;
$$;

GRANT EXECUTE ON FUNCTION public.fetch_user_post_social_state(uuid, uuid[])
  TO authenticated;

COMMENT ON FUNCTION public.fetch_user_post_social_state(uuid, uuid[]) IS
  'Returns liked/bookmarked flags for a batch of post IDs for the given user. '
  'Single-round-trip replacement for parallel SELECTs against community_likes '
  'and community_bookmarks during feed enrichment.';
