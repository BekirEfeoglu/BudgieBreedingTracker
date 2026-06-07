-- =============================================================================
-- Harden community writes behind moderated Edge Functions
-- =============================================================================
-- Public community posts/comments and community photos are user-generated
-- content. Client-side moderation remains useful for UX, but enforcement must
-- live server-side. This migration:
--   1. Moves direct post/comment INSERT access behind deny-all RLS policies.
--   2. Lets Edge Functions insert with service_role while preserving post rate
--      and duplicate guards by evaluating guards for NEW.user_id.
--   3. Adds a server-filtered, reciprocal-block-aware feed RPC with stable
--      timestamp + id pagination.
--   4. Removes community-photos from authenticated INSERT/UPDATE storage
--      policies; uploads must use upload-community-photo.
--   5. Rejects self-reports before report aggregation can increment counts.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. User-parametrized post guard for Edge Function service-role inserts.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.check_community_post_allowed_for_user(
  p_user_id uuid,
  p_content_hash text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_account_created_at timestamptz;
  v_hourly_count int;
  v_daily_count int;
  v_duplicate_exists boolean;
BEGIN
  IF p_user_id IS NULL THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'unauthorized');
  END IF;

  SELECT created_at INTO v_account_created_at
  FROM public.profiles
  WHERE id = p_user_id;

  IF v_account_created_at IS NULL THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'profile_not_found');
  END IF;

  IF (now() - v_account_created_at) < interval '24 hours' THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'account_too_new');
  END IF;

  SELECT count(*) INTO v_hourly_count
  FROM public.community_posts
  WHERE user_id = p_user_id
    AND is_deleted = false
    AND created_at > now() - interval '1 hour';

  IF v_hourly_count >= 5 THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'rate_limit_hourly');
  END IF;

  SELECT count(*) INTO v_daily_count
  FROM public.community_posts
  WHERE user_id = p_user_id
    AND is_deleted = false
    AND created_at > now() - interval '24 hours';

  IF v_daily_count >= 20 THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'rate_limit_daily');
  END IF;

  IF p_content_hash IS NOT NULL AND p_content_hash != '' THEN
    SELECT EXISTS(
      SELECT 1
      FROM public.community_posts
      WHERE user_id = p_user_id
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

REVOKE ALL ON FUNCTION private.check_community_post_allowed_for_user(uuid, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.check_community_post_allowed_for_user(uuid, text)
  TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.check_community_post_allowed(
  p_content_hash text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.check_community_post_allowed_for_user(
    (SELECT auth.uid()),
    p_content_hash
  );
$$;

GRANT EXECUTE ON FUNCTION public.check_community_post_allowed(text)
  TO authenticated;

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
  IF public.is_admin() THEN
    RETURN NEW;
  END IF;

  v_result := private.check_community_post_allowed_for_user(
    NEW.user_id,
    NEW.content_hash
  );

  IF (v_result->>'allowed')::boolean IS DISTINCT FROM true THEN
    v_reason := coalesce(v_result->>'reason', 'denied');
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'community_post_guard_denied',
      DETAIL  = v_reason,
      HINT    = 'Matches create-community-post guard reason codes';
  END IF;

  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 2. Disable direct client INSERT for public community UGC tables.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can insert own posts" ON public.community_posts;
DROP POLICY IF EXISTS "community_posts_insert_requires_edge_function"
  ON public.community_posts;
CREATE POLICY "community_posts_insert_requires_edge_function"
  ON public.community_posts
  FOR INSERT
  TO authenticated
  WITH CHECK (false);

DROP POLICY IF EXISTS "Users can insert own comments"
  ON public.community_comments;
DROP POLICY IF EXISTS "community_comments_insert_requires_edge_function"
  ON public.community_comments;
CREATE POLICY "community_comments_insert_requires_edge_function"
  ON public.community_comments
  FOR INSERT
  TO authenticated
  WITH CHECK (false);

GRANT INSERT ON TABLE public.community_posts TO service_role;
GRANT INSERT ON TABLE public.community_comments TO service_role;

-- ---------------------------------------------------------------------------
-- 3. Reciprocal-block-aware post visibility + stable feed RPC.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Anyone can view public posts" ON public.community_posts;
DROP POLICY IF EXISTS "Users can view posts" ON public.community_posts;
CREATE POLICY "Users can view posts"
  ON public.community_posts
  FOR SELECT
  TO authenticated
  USING (
    (
      (visibility = 'public' AND is_deleted = false)
      OR (SELECT auth.uid()) = user_id
    )
    AND (
      (SELECT auth.uid()) = user_id
      OR NOT EXISTS (
        SELECT 1
        FROM public.community_blocks b
        WHERE (
          b.user_id = (SELECT auth.uid())
          AND b.blocked_user_id = community_posts.user_id
        )
        OR (
          b.user_id = community_posts.user_id
          AND b.blocked_user_id = (SELECT auth.uid())
        )
      )
    )
  );

CREATE OR REPLACE FUNCTION public.fetch_community_feed(
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

-- ---------------------------------------------------------------------------
-- 4. Community photo writes must go through upload-community-photo.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can insert own private bucket objects"
  ON storage.objects;
CREATE POLICY "Users can insert own private bucket objects"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id IN ('bird-photos', 'egg-photos', 'chick-photos', 'backups')
  AND (storage.foldername(name))[1] = (select auth.uid())::text
);

DROP POLICY IF EXISTS "Users can update own private bucket objects"
  ON storage.objects;
CREATE POLICY "Users can update own private bucket objects"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id IN ('bird-photos', 'egg-photos', 'chick-photos', 'backups')
  AND (storage.foldername(name))[1] = (select auth.uid())::text
)
WITH CHECK (
  bucket_id IN ('bird-photos', 'egg-photos', 'chick-photos', 'backups')
  AND (storage.foldername(name))[1] = (select auth.uid())::text
);

DROP POLICY IF EXISTS "community_photo_client_insert_disabled"
  ON storage.objects;
CREATE POLICY "community_photo_client_insert_disabled"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'community-photos' AND false);

DROP POLICY IF EXISTS "community_photo_client_update_disabled"
  ON storage.objects;
CREATE POLICY "community_photo_client_update_disabled"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'community-photos' AND false)
WITH CHECK (bucket_id = 'community-photos' AND false);

-- ---------------------------------------------------------------------------
-- 5. Reject self-reports before aggregation increments target counts.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.prevent_self_community_report()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_target_owner uuid;
BEGIN
  IF NEW.target_type = 'post' THEN
    SELECT user_id INTO v_target_owner
    FROM public.community_posts
    WHERE id = NEW.target_id;
  ELSIF NEW.target_type = 'comment' THEN
    SELECT user_id INTO v_target_owner
    FROM public.community_comments
    WHERE id = NEW.target_id;
  END IF;

  IF v_target_owner IS NOT NULL AND v_target_owner = NEW.user_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'community_self_report_denied',
      DETAIL  = 'Users cannot report their own community content';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_self_community_report
  ON public.community_reports;

CREATE TRIGGER trg_prevent_self_community_report
  BEFORE INSERT ON public.community_reports
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_self_community_report();

COMMENT ON FUNCTION public.prevent_self_community_report() IS
  'Rejects reports where the reporting user owns the target post/comment. '
  'Runs before report aggregation so self-reports cannot inflate counts.';
