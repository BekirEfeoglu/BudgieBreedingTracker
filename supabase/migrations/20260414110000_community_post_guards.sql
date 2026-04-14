-- =============================================================================
-- Migration: Community post rate limit, account age gate, and spam detection
-- Date: 2026-04-14
-- Purpose: Server-side guards to prevent spam, enforce account maturity,
--          and rate-limit post creation (App Store Guideline 1.2 compliance).
--
-- Guards:
--   1. Account age: must be 24h+ old to create posts
--   2. Rate limit: max 5 posts/hour, 20 posts/day
--   3. Spam dedup: reject identical content within 1 hour (MD5 hash)
-- =============================================================================

-- Add content_hash column for spam dedup detection.
ALTER TABLE public.community_posts
ADD COLUMN IF NOT EXISTS content_hash text;

-- Index for efficient rate limit and dedup queries per user.
CREATE INDEX IF NOT EXISTS idx_community_posts_user_created
ON public.community_posts (user_id, created_at DESC)
WHERE is_deleted = false;

CREATE INDEX IF NOT EXISTS idx_community_posts_user_content_hash
ON public.community_posts (user_id, content_hash)
WHERE is_deleted = false AND content_hash IS NOT NULL;

-- RPC: Validate whether a user can create a post.
-- Returns { allowed: true } or { allowed: false, reason: string }.
-- Called by client BEFORE inserting into community_posts.
CREATE OR REPLACE FUNCTION public.check_community_post_allowed(
  p_content_hash text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid;
  v_account_created_at timestamptz;
  v_hourly_count int;
  v_daily_count int;
  v_duplicate_exists boolean;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'unauthorized');
  END IF;

  -- 1. Account age gate: must be at least 24 hours old
  SELECT created_at INTO v_account_created_at
  FROM public.profiles
  WHERE id = v_user_id;

  IF v_account_created_at IS NULL THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'profile_not_found');
  END IF;

  IF (now() - v_account_created_at) < interval '24 hours' THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'account_too_new');
  END IF;

  -- 2. Rate limit: max 5 posts per hour
  SELECT count(*) INTO v_hourly_count
  FROM public.community_posts
  WHERE user_id = v_user_id
    AND is_deleted = false
    AND created_at > now() - interval '1 hour';

  IF v_hourly_count >= 5 THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'rate_limit_hourly');
  END IF;

  -- 3. Rate limit: max 20 posts per day
  SELECT count(*) INTO v_daily_count
  FROM public.community_posts
  WHERE user_id = v_user_id
    AND is_deleted = false
    AND created_at > now() - interval '24 hours';

  IF v_daily_count >= 20 THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'rate_limit_daily');
  END IF;

  -- 4. Spam dedup: reject identical content within 1 hour
  IF p_content_hash IS NOT NULL AND p_content_hash != '' THEN
    SELECT EXISTS(
      SELECT 1 FROM public.community_posts
      WHERE user_id = v_user_id
        AND content_hash = p_content_hash
        AND is_deleted = false
        AND created_at > now() - interval '1 hour'
    ) INTO v_duplicate_exists;

    IF v_duplicate_exists THEN
      RETURN jsonb_build_object('allowed', false, 'reason', 'duplicate_content');
    END IF;
  END IF;

  RETURN jsonb_build_object('allowed', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_community_post_allowed(text) TO authenticated;

COMMENT ON FUNCTION public.check_community_post_allowed IS
  'Validates whether the authenticated user can create a community post. '
  'Checks account age (24h), hourly rate (5/h), daily rate (20/d), '
  'and duplicate content (MD5 hash within 1h).';
