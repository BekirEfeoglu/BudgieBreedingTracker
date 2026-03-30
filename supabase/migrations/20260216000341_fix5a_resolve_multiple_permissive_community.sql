
-- Fix 5a: Resolve multiple permissive policies for community tables
-- Problem: FOR ALL (includes SELECT) + separate FOR SELECT = duplicate SELECT evaluation
-- Solution: Replace ALL with INSERT/UPDATE/DELETE, keep the "Anyone can view" SELECT

-- ========== COMMUNITY_POSTS ==========
DROP POLICY IF EXISTS "Users can manage own posts" ON community_posts;
CREATE POLICY "Users can insert own posts" ON community_posts FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own posts" ON community_posts FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own posts" ON community_posts FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);
-- Extend the existing "Anyone can view public posts" to also let owners see own drafts
DROP POLICY IF EXISTS "Anyone can view public posts" ON community_posts;
CREATE POLICY "Users can view posts" ON community_posts FOR SELECT TO authenticated
  USING ((visibility = 'public' AND is_deleted = false) OR (select auth.uid()) = user_id);

-- ========== COMMUNITY_COMMENTS ==========
DROP POLICY IF EXISTS "Users can manage own comments" ON community_comments;
DROP POLICY IF EXISTS "Anyone can view comments on public posts" ON community_comments;
CREATE POLICY "Users can view comments" ON community_comments FOR SELECT TO authenticated
  USING (is_deleted = false OR (select auth.uid()) = user_id);
CREATE POLICY "Users can insert own comments" ON community_comments FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own comments" ON community_comments FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own comments" ON community_comments FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== COMMUNITY_LIKES ==========
DROP POLICY IF EXISTS "Users can manage own likes" ON community_likes;
DROP POLICY IF EXISTS "Anyone can view likes" ON community_likes;
CREATE POLICY "Anyone can view likes" ON community_likes FOR SELECT TO authenticated
  USING (true);
CREATE POLICY "Users can insert own likes" ON community_likes FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own likes" ON community_likes FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== COMMUNITY_COMMENT_LIKES ==========
DROP POLICY IF EXISTS "Users can manage own comment likes" ON community_comment_likes;
DROP POLICY IF EXISTS "Anyone can view comment likes" ON community_comment_likes;
CREATE POLICY "Anyone can view comment likes" ON community_comment_likes FOR SELECT TO authenticated
  USING (true);
CREATE POLICY "Users can insert own comment likes" ON community_comment_likes FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own comment likes" ON community_comment_likes FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== COMMUNITY_EVENTS ==========
DROP POLICY IF EXISTS "Users can manage own events" ON community_events;
DROP POLICY IF EXISTS "Anyone can view events" ON community_events;
CREATE POLICY "Users can view events" ON community_events FOR SELECT TO authenticated
  USING (is_deleted = false OR (select auth.uid()) = user_id);
CREATE POLICY "Users can insert own events" ON community_events FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own events" ON community_events FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own events" ON community_events FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== COMMUNITY_EVENT_ATTENDEES ==========
DROP POLICY IF EXISTS "Users can manage own attendance" ON community_event_attendees;
DROP POLICY IF EXISTS "Anyone can view attendees" ON community_event_attendees;
CREATE POLICY "Anyone can view attendees" ON community_event_attendees FOR SELECT TO authenticated
  USING (true);
CREATE POLICY "Users can insert own attendance" ON community_event_attendees FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own attendance" ON community_event_attendees FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== COMMUNITY_POLL_VOTES ==========
DROP POLICY IF EXISTS "Users can manage own votes" ON community_poll_votes;
DROP POLICY IF EXISTS "Anyone can view vote counts" ON community_poll_votes;
CREATE POLICY "Anyone can view vote counts" ON community_poll_votes FOR SELECT TO authenticated
  USING (true);
CREATE POLICY "Users can insert own votes" ON community_poll_votes FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own votes" ON community_poll_votes FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== COMMUNITY_STORIES ==========
DROP POLICY IF EXISTS "Users can manage own stories" ON community_stories;
DROP POLICY IF EXISTS "Anyone can view active stories" ON community_stories;
CREATE POLICY "Users can view stories" ON community_stories FOR SELECT TO authenticated
  USING ((expires_at > now() AND is_deleted = false) OR (select auth.uid()) = user_id);
CREATE POLICY "Users can insert own stories" ON community_stories FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own stories" ON community_stories FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own stories" ON community_stories FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);
;
