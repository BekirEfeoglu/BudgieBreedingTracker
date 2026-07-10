-- 20260710160000_add_community_tag_gin_indexes.sql
--
-- Backs the community tag / mutation-tag discovery feed (CommunityPostRemoteSource
-- .fetchByTag → RPC get_community_posts_by_tag).
--
-- `tags` is jsonb (array of strings) and `mutation_tags` is text[], so the two
-- containment checks use different operators:
--   * jsonb array element existence: `tags ? p_tag`   (GIN default jsonb_ops)
--   * text[] containment:            `mutation_tags @> array[p_tag]` (GIN)
-- A PostgREST `.or()` can't cleanly express this mixed shape, so a small
-- STABLE SECURITY INVOKER RPC does the OR (RLS still applies — community_posts
-- SELECT is public for non-deleted rows).
--
-- Idempotent (IF NOT EXISTS / CREATE OR REPLACE) so a replay is a no-op.

CREATE INDEX IF NOT EXISTS idx_community_posts_tags_gin
  ON public.community_posts USING GIN (tags);

CREATE INDEX IF NOT EXISTS idx_community_posts_mutation_tags_gin
  ON public.community_posts USING GIN (mutation_tags);

COMMENT ON INDEX public.idx_community_posts_tags_gin IS
  'Element-existence lookups for the free-tag discovery feed (get_community_posts_by_tag).';
COMMENT ON INDEX public.idx_community_posts_mutation_tags_gin IS
  'Array-containment lookups for the mutation-tag discovery feed (get_community_posts_by_tag).';

CREATE OR REPLACE FUNCTION public.get_community_posts_by_tag(
  p_tag text,
  p_limit integer DEFAULT 30
)
RETURNS SETOF public.community_posts
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT *
  FROM public.community_posts
  WHERE is_deleted = false
    AND needs_review = false
    AND (tags ? p_tag OR mutation_tags @> ARRAY[p_tag])
  ORDER BY created_at DESC
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 30), 1), 100);
$$;

GRANT EXECUTE ON FUNCTION public.get_community_posts_by_tag(text, integer)
  TO anon, authenticated;
