-- =============================================================================
-- Community post edit (5-minute window) hardening
-- =============================================================================
-- 1. edited_at column for the "edited" badge.
-- 2. Narrow authenticated UPDATE to (is_deleted, needs_review, reviewed_by):
--    content edits must go through the moderated create-community-post edge
--    function (mode: 'update', service_role). Closes the pre-existing
--    direct-content-update moderation bypass.
--    Client UPDATE call sites preserved: softDelete (is_deleted),
--    clearReviewFlag (needs_review, reviewed_by).
-- 3. fetch_community_feed returns edited_at.
-- =============================================================================

ALTER TABLE public.community_posts
  ADD COLUMN IF NOT EXISTS edited_at timestamptz;

COMMENT ON COLUMN public.community_posts.edited_at IS
  'Set by create-community-post edge fn (mode=update) within the 5-minute edit window';

REVOKE UPDATE ON TABLE public.community_posts FROM authenticated;
GRANT UPDATE (is_deleted, needs_review, reviewed_by)
  ON TABLE public.community_posts TO authenticated;

-- RETURNS TABLE kolon listesi değiştiği için CREATE OR REPLACE yetmez:
-- Postgres "cannot change return type of existing function" hatası verir.
DROP FUNCTION IF EXISTS public.fetch_community_feed(integer, timestamptz, uuid);

CREATE FUNCTION public.fetch_community_feed(
  p_limit integer DEFAULT 20,
  p_before_created_at timestamptz DEFAULT NULL,
  p_before_id uuid DEFAULT NULL
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
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
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
$$;

REVOKE ALL ON FUNCTION public.fetch_community_feed(integer, timestamptz, uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fetch_community_feed(integer, timestamptz, uuid)
  TO authenticated;
