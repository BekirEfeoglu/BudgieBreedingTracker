-- =============================================================================
-- Community feed sort enhancement
-- =============================================================================
-- Modifies fetch_community_feed to accept an optional p_sort_by parameter.
-- Supports 'newest' (default) and 'trending' (like_count DESC, created_at DESC).
-- =============================================================================

DROP FUNCTION IF EXISTS public.fetch_community_feed(integer, timestamptz, uuid);
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
  is_deleted boolean
)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF p_sort_by = 'trending' THEN
    RETURN QUERY
    SELECT
      p.id,
      p.user_id,
      p.content,
      p.title,
      p.post_type,
      p.image_urls,
      p.tags,
      p.like_count,
      p.comment_count,
      p.view_count,
      p.is_pinned,
      p.visibility,
      p.created_at,
      p.updated_at,
      p.edited_at,
      p.is_deleted
    FROM public.community_posts p
    WHERE (SELECT auth.uid()) IS NOT NULL
      AND p.visibility = 'public'
      AND p.is_deleted = false
      AND p.needs_review = false
      AND (
        p_before_created_at IS NULL
        OR p.created_at < p_before_created_at
        OR (
          p_before_id IS NOT NULL
          AND p.created_at = p_before_created_at
          AND p.id < p_before_id
        )
      )
      AND (
        p.user_id = (SELECT auth.uid())
        OR NOT EXISTS (
          SELECT 1
          FROM public.community_blocks b
          WHERE (
            b.user_id = (SELECT auth.uid())
            AND b.blocked_user_id = p.user_id
          )
          OR (
            b.user_id = p.user_id
            AND b.blocked_user_id = (SELECT auth.uid())
          )
        )
      )
    ORDER BY p.like_count DESC, p.created_at DESC, p.id DESC
    LIMIT least(greatest(coalesce(p_limit, 20), 1), 50);
  ELSE
    RETURN QUERY
    SELECT
      p.id,
      p.user_id,
      p.content,
      p.title,
      p.post_type,
      p.image_urls,
      p.tags,
      p.like_count,
      p.comment_count,
      p.view_count,
      p.is_pinned,
      p.visibility,
      p.created_at,
      p.updated_at,
      p.edited_at,
      p.is_deleted
    FROM public.community_posts p
    WHERE (SELECT auth.uid()) IS NOT NULL
      AND p.visibility = 'public'
      AND p.is_deleted = false
      AND p.needs_review = false
      AND (
        p_before_created_at IS NULL
        OR p.created_at < p_before_created_at
        OR (
          p_before_id IS NOT NULL
          AND p.created_at = p_before_created_at
          AND p.id < p_before_id
        )
      )
      AND (
        p.user_id = (SELECT auth.uid())
        OR NOT EXISTS (
          SELECT 1
          FROM public.community_blocks b
          WHERE (
            b.user_id = (SELECT auth.uid())
            AND b.blocked_user_id = p.user_id
          )
          OR (
            b.user_id = p.user_id
            AND b.blocked_user_id = (SELECT auth.uid())
          )
        )
      )
    ORDER BY p.created_at DESC, p.id DESC
    LIMIT least(greatest(coalesce(p_limit, 20), 1), 50);
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.fetch_community_feed(integer, timestamptz, uuid, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fetch_community_feed(integer, timestamptz, uuid, text)
  TO authenticated;
