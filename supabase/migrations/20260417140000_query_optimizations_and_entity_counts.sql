-- =============================================================================
-- Migration: Query optimizations + get_entity_counts RPC
-- Date: 2026-04-17
-- Fixes:
--   1. Missing composite index for community comments feed query
--      (post_id + is_deleted filter, created_at ASC sort).
--   2. Moderation queue index: needs_review posts ordered by created_at DESC.
--   3. xp_transactions: (user_id, created_at DESC) composite avoids in-memory
--      sort for fetchXpTransactions.
--   4. marketplace_listings: covering index for public feed filters.
--   5. get_entity_counts RPC: consolidates 4 round-trips into 1 for the
--      verified-breeder criteria check.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. community_comments: (post_id, created_at) partial composite
-- Query: WHERE post_id = ? AND is_deleted = false ORDER BY created_at ASC
-- Existing idx_community_comments_post (post_id only) forces an in-memory sort
-- plus a separate filter on is_deleted. Partial composite eliminates both.
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_community_comments_post_created
  ON public.community_comments (post_id, created_at)
  WHERE is_deleted = false;

-- -----------------------------------------------------------------------------
-- 2. community_posts: moderation review queue
-- Query: WHERE needs_review = true AND is_deleted = false ORDER BY created_at DESC
-- Existing idx_community_posts_needs_review (needs_review) WHERE needs_review=true
-- still requires sort + heap lookup. This partial index on created_at DESC
-- serves the admin review queue directly.
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_community_posts_review_queue
  ON public.community_posts (created_at DESC)
  WHERE needs_review = true AND is_deleted = false;

-- -----------------------------------------------------------------------------
-- 3. xp_transactions: (user_id, created_at DESC) composite
-- Query: WHERE user_id = ? ORDER BY created_at DESC LIMIT 50
-- Existing idx_xp_transactions_user_action_date (user_id, action, created_at ASC)
-- cannot serve the user-scoped DESC sort efficiently.
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_xp_transactions_user_created
  ON public.xp_transactions (user_id, created_at DESC);

-- -----------------------------------------------------------------------------
-- 4. marketplace_listings: public feed filter + sort
-- Query: WHERE is_deleted = false AND status = 'active' [optional filters]
--        ORDER BY created_at DESC LIMIT 20
-- Existing single-column indexes on city/listing_type/gender/status/created_at
-- don't combine. Partial composite covers the always-present filters and the
-- sort key. Optional filters (city/listing_type/gender/price) still benefit
-- from their individual indexes as bitmap-combined scans.
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_feed
  ON public.marketplace_listings (created_at DESC)
  WHERE is_deleted = false AND status = 'active' AND needs_review = false;

-- -----------------------------------------------------------------------------
-- 5. get_entity_counts RPC
-- Replaces 4 separate .select('id')..eq('user_id', ?) calls in
-- GamificationRemoteSource.fetchEntityCounts with a single round-trip.
-- Returns counts for verified-breeder criteria check.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_entity_counts(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller uuid;
BEGIN
  -- Only allow callers to query their own counts. Admin panels should use
  -- a separate admin-scoped RPC if cross-user counts are required.
  v_caller := (SELECT auth.uid());
  IF v_caller IS NULL OR v_caller <> p_user_id THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;

  RETURN jsonb_build_object(
    'birds', (
      SELECT count(*) FROM public.birds
      WHERE user_id = p_user_id AND is_deleted = false
    ),
    'breeding_pairs', (
      SELECT count(*) FROM public.breeding_pairs
      WHERE user_id = p_user_id AND is_deleted = false
    ),
    'chicks', (
      SELECT count(*) FROM public.chicks
      WHERE user_id = p_user_id AND is_deleted = false
    ),
    'posts', (
      SELECT count(*) FROM public.community_posts
      WHERE user_id = p_user_id AND is_deleted = false
    )
  );
END;
$$;

-- Restrict execution to authenticated users; anon cannot call this.
REVOKE EXECUTE ON FUNCTION public.get_entity_counts(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_entity_counts(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_entity_counts(uuid) TO authenticated;

COMMENT ON FUNCTION public.get_entity_counts(uuid) IS
  'Returns active entity counts for verified-breeder criteria (birds, '
  'breeding_pairs, chicks, posts). Caller must equal p_user_id.';
