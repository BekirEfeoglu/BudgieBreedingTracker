-- =============================================================================
-- RLS Performance Optimization & Policy Gap Fixes
-- =============================================================================
-- Fixes:
--   1. (select auth.uid()) optimization for mfa_lockouts, community_follows,
--      community_reports (per-row function call → single InitPlan evaluation)
--   2. Missing indexes on RLS-critical columns (visibility, is_system,
--      incubations user_id+is_deleted)
--   3. Missing admin SELECT policies (community_reports, community_follows)
--   4. is_admin() consistency (community_posts admin UPDATE policy)
--   5. Missing DELETE policy on mfa_lockouts
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. mfa_lockouts: Replace bare auth.uid() with (select auth.uid())
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can read own mfa_lockout" ON mfa_lockouts;
CREATE POLICY "Users can read own mfa_lockout"
  ON mfa_lockouts FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own mfa_lockout" ON mfa_lockouts;
CREATE POLICY "Users can update own mfa_lockout"
  ON mfa_lockouts FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own mfa_lockout" ON mfa_lockouts;
CREATE POLICY "Users can insert own mfa_lockout"
  ON mfa_lockouts FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

-- Add DELETE policy so users (or service_role on their behalf) can clean up
CREATE POLICY "Users can delete own mfa_lockout"
  ON mfa_lockouts FOR DELETE
  TO authenticated
  USING ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- 2. community_follows: Replace bare auth.uid() with (select auth.uid())
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view their own follows" ON community_follows;
CREATE POLICY "Users can view their own follows"
  ON community_follows FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = follower_id OR (select auth.uid()) = following_id);

DROP POLICY IF EXISTS "Users can follow others" ON community_follows;
CREATE POLICY "Users can follow others"
  ON community_follows FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = follower_id);

DROP POLICY IF EXISTS "Users can unfollow" ON community_follows;
CREATE POLICY "Users can unfollow"
  ON community_follows FOR DELETE
  TO authenticated
  USING ((select auth.uid()) = follower_id);

-- Admin SELECT for moderation panel
CREATE POLICY "Admins can view all follows"
  ON community_follows FOR SELECT
  TO authenticated
  USING ((select public.is_admin()));

-- ---------------------------------------------------------------------------
-- 3. community_reports: Replace bare auth.uid() with (select auth.uid())
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view their own reports" ON community_reports;
CREATE POLICY "Users can view their own reports"
  ON community_reports FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can create reports" ON community_reports;
CREATE POLICY "Users can create reports"
  ON community_reports FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

-- Admin SELECT for moderation panel
CREATE POLICY "Admins can view all reports"
  ON community_reports FOR SELECT
  TO authenticated
  USING ((select public.is_admin()));

-- ---------------------------------------------------------------------------
-- 4. community_posts: Replace EXISTS subquery with is_admin() for consistency
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Admins can update posts for moderation" ON community_posts;
CREATE POLICY "Admins can update posts for moderation"
  ON community_posts FOR UPDATE
  TO authenticated
  USING ((select public.is_admin()))
  WITH CHECK ((select public.is_admin()));

-- ---------------------------------------------------------------------------
-- 5. Missing performance indexes for RLS-critical columns
-- ---------------------------------------------------------------------------

-- community_posts.visibility — used in RLS (visibility = 'public')
CREATE INDEX IF NOT EXISTS idx_community_posts_visibility
  ON community_posts(visibility)
  WHERE visibility = 'public';

-- event_types.is_system — used in RLS (is_system = true OR user_id = ...)
CREATE INDEX IF NOT EXISTS idx_event_types_is_system
  ON event_types(is_system)
  WHERE is_system = true;

-- event_templates.is_system — same pattern
CREATE INDEX IF NOT EXISTS idx_event_templates_is_system
  ON event_templates(is_system)
  WHERE is_system = true;

-- incubations (user_id) — incubations uses BaseRemoteSourceNoSoftDelete (no is_deleted column)
CREATE INDEX IF NOT EXISTS idx_incubations_user_id_v2
  ON incubations(user_id);
