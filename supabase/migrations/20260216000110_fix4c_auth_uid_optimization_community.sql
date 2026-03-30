
-- Fix 4c: Replace auth.uid() with (select auth.uid()) for community tables

-- ========== COMMUNITY_POSTS ==========
DROP POLICY IF EXISTS "Users can manage own posts" ON community_posts;
CREATE POLICY "Users can manage own posts" ON community_posts FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== COMMUNITY_COMMENTS ==========
DROP POLICY IF EXISTS "Users can manage own comments" ON community_comments;
CREATE POLICY "Users can manage own comments" ON community_comments FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== COMMUNITY_LIKES ==========
DROP POLICY IF EXISTS "Users can manage own likes" ON community_likes;
CREATE POLICY "Users can manage own likes" ON community_likes FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== COMMUNITY_COMMENT_LIKES ==========
DROP POLICY IF EXISTS "Users can manage own comment likes" ON community_comment_likes;
CREATE POLICY "Users can manage own comment likes" ON community_comment_likes FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== COMMUNITY_BOOKMARKS ==========
DROP POLICY IF EXISTS "Users can manage own bookmarks" ON community_bookmarks;
CREATE POLICY "Users can manage own bookmarks" ON community_bookmarks FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== COMMUNITY_EVENTS ==========
DROP POLICY IF EXISTS "Users can manage own events" ON community_events;
CREATE POLICY "Users can manage own events" ON community_events FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== COMMUNITY_EVENT_ATTENDEES ==========
DROP POLICY IF EXISTS "Users can manage own attendance" ON community_event_attendees;
CREATE POLICY "Users can manage own attendance" ON community_event_attendees FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== COMMUNITY_POLLS ==========
DROP POLICY IF EXISTS "Users can create polls" ON community_polls;
CREATE POLICY "Users can create polls" ON community_polls FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM community_posts
    WHERE community_posts.id = community_polls.post_id
      AND community_posts.user_id = (select auth.uid())
  ));

-- ========== COMMUNITY_POLL_VOTES ==========
DROP POLICY IF EXISTS "Users can manage own votes" ON community_poll_votes;
CREATE POLICY "Users can manage own votes" ON community_poll_votes FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== COMMUNITY_STORIES ==========
DROP POLICY IF EXISTS "Users can manage own stories" ON community_stories;
CREATE POLICY "Users can manage own stories" ON community_stories FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== COMMUNITY_STORY_VIEWS ==========
DROP POLICY IF EXISTS "Story owners can view who watched" ON community_story_views;
DROP POLICY IF EXISTS "Users can insert own views" ON community_story_views;

CREATE POLICY "Story owners can view who watched" ON community_story_views FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM community_stories
      WHERE community_stories.id = community_story_views.story_id
        AND community_stories.user_id = (select auth.uid())
    ) OR (select auth.uid()) = user_id
  );
CREATE POLICY "Users can insert own views" ON community_story_views FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
;
