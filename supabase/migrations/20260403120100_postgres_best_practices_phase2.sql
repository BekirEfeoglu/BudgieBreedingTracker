-- =============================================================================
-- Migration: Postgres Best Practices Phase 2
-- Date: 2026-04-03
-- Fixes:
--   1. Merge duplicate permissive policies (4 remaining WARN items)
--   2. Move pg_trgm extension from public to extensions schema
--   3. (unused indexes kept - app is early stage, they'll be used at scale)
-- =============================================================================

-- =====================================================
-- 1. MERGE DUPLICATE PERMISSIVE POLICIES
-- Multiple permissive policies for same role+action are OR'd together,
-- causing redundant evaluation. Merging into single policies is more efficient.
-- =====================================================

-- --- conversation_participants: merge 2 SELECT policies into 1 ---
-- participants_own_read: user_id = auth.uid() (see own rows, even if left)
-- participants_conversation_read: is_conversation_member() (see all in conversation)
-- Merged: single policy with OR

DROP POLICY IF EXISTS "participants_own_read" ON conversation_participants;
DROP POLICY IF EXISTS "participants_conversation_read" ON conversation_participants;
CREATE POLICY "participants_select" ON conversation_participants
  FOR SELECT TO authenticated
  USING (
    user_id = (select auth.uid())
    OR is_conversation_member(conversation_id, (select auth.uid()))
  );

-- --- community_follows: merge admin + user SELECT policies into 1 ---

DROP POLICY IF EXISTS "Admins can view all follows" ON community_follows;
DROP POLICY IF EXISTS "Users can view their own follows" ON community_follows;
CREATE POLICY "community_follows_select" ON community_follows
  FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = follower_id
    OR (select auth.uid()) = following_id
    OR (select is_admin())
  );

-- --- community_posts: merge admin + user UPDATE policies into 1 ---

DROP POLICY IF EXISTS "Admins can update posts for moderation" ON community_posts;
DROP POLICY IF EXISTS "Users can update own posts" ON community_posts;
CREATE POLICY "community_posts_update" ON community_posts
  FOR UPDATE TO authenticated
  USING (
    (select auth.uid()) = user_id
    OR (select is_admin())
  )
  WITH CHECK (
    (select auth.uid()) = user_id
    OR (select is_admin())
  );

-- --- community_reports: merge admin + user SELECT policies into 1 ---

DROP POLICY IF EXISTS "Admins can view all reports" ON community_reports;
DROP POLICY IF EXISTS "Users can view their own reports" ON community_reports;
CREATE POLICY "community_reports_select" ON community_reports
  FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id
    OR (select is_admin())
  );


-- =====================================================
-- 2. MOVE pg_trgm EXTENSION from public to extensions schema
-- Extensions in public schema pollute the namespace and can be
-- a security concern. Supabase recommends the extensions schema.
-- =====================================================

-- Move extension (indexes using gin_trgm_ops continue to work)
ALTER EXTENSION pg_trgm SET SCHEMA extensions;
