-- =============================================================================
-- fetch_community_feed: return is_following_author
-- =============================================================================
-- The feed RPC never returned the viewer's follow state, so
-- `CommunityPost.isFollowingAuthor` was permanently false until 2026-07-14, when
-- CommunityPostRepository._enrichPosts started deriving it from a second query
-- (fetchFollowedUserIds). That works for every fetch path, but costs the feed an
-- extra round-trip on every page.
--
-- Emit the flag straight from the RPC so the feed needs one call. The other post
-- paths (fetchById / fetchByUser / fetchByTag / fetchByIds) are plain selects and
-- still rely on the repository-side lookup, which is why the client keeps that
-- fallback and only skips it when the rows already carry the column.
--
-- Backward compatible: the parameter list is unchanged (older app binaries call
-- the same signature and simply ignore the extra column), and
-- `_parsePost` already prefers `row['is_following_author']` when present.
--
-- The function stays SECURITY INVOKER: the EXISTS runs under the caller's RLS,
-- and `community_follows_select` already allows a user to read rows where they
-- are the follower — exactly the rows this needs.
--
-- RETURNS TABLE changed => the function must be dropped and recreated (CREATE OR
-- REPLACE cannot change the return type). Grants are restored explicitly:
-- pre-drop they were {authenticated=X, service_role=X} with no PUBLIC grant.
-- =============================================================================

DROP FUNCTION IF EXISTS public.fetch_community_feed(integer, timestamptz, uuid, text);

CREATE FUNCTION public.fetch_community_feed(
  p_limit integer DEFAULT 20,
  p_before_created_at timestamptz DEFAULT NULL,
  p_before_id uuid DEFAULT NULL,
  p_sort_by text DEFAULT 'newest'
)
RETURNS TABLE(
  id uuid,
  user_id uuid,
  content text,
  title text,
  post_type text,
  image_urls jsonb,
  tags jsonb,
  like_count integer,
  comment_count integer,
  view_count integer,
  is_pinned boolean,
  visibility text,
  created_at timestamptz,
  updated_at timestamptz,
  edited_at timestamptz,
  is_deleted boolean,
  is_following_author boolean
)
LANGUAGE plpgsql
STABLE
SET search_path TO ''
AS $function$
BEGIN
  IF p_sort_by = 'trending' THEN
    RETURN QUERY
    SELECT
      p.id, p.user_id, p.content, p.title, p.post_type, p.image_urls, p.tags,
      p.like_count, p.comment_count, p.view_count, p.is_pinned, p.visibility,
      p.created_at, p.updated_at, p.edited_at, p.is_deleted,
      EXISTS (
        SELECT 1 FROM public.community_follows f
        WHERE f.follower_id = (SELECT auth.uid())
          AND f.following_id = p.user_id
      ) AS is_following_author
    FROM public.community_posts p
    WHERE (SELECT auth.uid()) IS NOT NULL
      AND p.visibility = 'public'
      AND p.is_deleted = false
      AND p.needs_review = false
      AND (
        p_before_created_at IS NULL
        OR p.created_at < p_before_created_at
        OR (p_before_id IS NOT NULL AND p.created_at = p_before_created_at AND p.id < p_before_id)
      )
      AND (
        p.user_id = (SELECT auth.uid())
        OR NOT EXISTS (
          SELECT 1 FROM public.community_blocks b
          WHERE (b.user_id = (SELECT auth.uid()) AND b.blocked_user_id = p.user_id)
            OR (b.user_id = p.user_id AND b.blocked_user_id = (SELECT auth.uid()))
        )
      )
    ORDER BY p.like_count DESC, p.created_at DESC, p.id DESC
    LIMIT least(greatest(coalesce(p_limit, 20), 1), 50);
  ELSE
    RETURN QUERY
    SELECT
      p.id, p.user_id, p.content, p.title, p.post_type, p.image_urls, p.tags,
      p.like_count, p.comment_count, p.view_count, p.is_pinned, p.visibility,
      p.created_at, p.updated_at, p.edited_at, p.is_deleted,
      EXISTS (
        SELECT 1 FROM public.community_follows f
        WHERE f.follower_id = (SELECT auth.uid())
          AND f.following_id = p.user_id
      ) AS is_following_author
    FROM public.community_posts p
    WHERE (SELECT auth.uid()) IS NOT NULL
      AND p.visibility = 'public'
      AND p.is_deleted = false
      AND p.needs_review = false
      AND (
        p_before_created_at IS NULL
        OR p.created_at < p_before_created_at
        OR (p_before_id IS NOT NULL AND p.created_at = p_before_created_at AND p.id < p_before_id)
      )
      AND (
        p.user_id = (SELECT auth.uid())
        OR NOT EXISTS (
          SELECT 1 FROM public.community_blocks b
          WHERE (b.user_id = (SELECT auth.uid()) AND b.blocked_user_id = p.user_id)
            OR (b.user_id = p.user_id AND b.blocked_user_id = (SELECT auth.uid()))
        )
      )
    ORDER BY p.created_at DESC, p.id DESC
    LIMIT least(greatest(coalesce(p_limit, 20), 1), 50);
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION public.fetch_community_feed(integer, timestamptz, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fetch_community_feed(integer, timestamptz, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fetch_community_feed(integer, timestamptz, uuid, text) TO service_role;
