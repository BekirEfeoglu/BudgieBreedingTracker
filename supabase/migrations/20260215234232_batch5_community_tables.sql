
-- =============================================
-- BATCH 5: Topluluk (Community) - 12 tablo
-- =============================================

-- 1. Community Posts (Kullanıcı paylaşımları)
CREATE TABLE community_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content text NOT NULL,
  post_type text NOT NULL DEFAULT 'text' CHECK (post_type IN ('text', 'photo', 'poll', 'question', 'tip', 'achievement')),
  image_urls jsonb DEFAULT '[]'::jsonb,
  tags jsonb DEFAULT '[]'::jsonb,
  like_count int NOT NULL DEFAULT 0,
  comment_count int NOT NULL DEFAULT 0,
  share_count int NOT NULL DEFAULT 0,
  view_count int NOT NULL DEFAULT 0,
  is_pinned boolean NOT NULL DEFAULT false,
  is_featured boolean NOT NULL DEFAULT false,
  is_reported boolean NOT NULL DEFAULT false,
  report_count int NOT NULL DEFAULT 0,
  visibility text NOT NULL DEFAULT 'public' CHECK (visibility IN ('public', 'followers', 'private')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  is_deleted boolean NOT NULL DEFAULT false
);

CREATE INDEX idx_community_posts_user_id ON community_posts(user_id);
CREATE INDEX idx_community_posts_created ON community_posts(created_at DESC);
CREATE INDEX idx_community_posts_type ON community_posts(post_type);

ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view public posts" ON community_posts
  FOR SELECT USING (visibility = 'public' AND is_deleted = false);
CREATE POLICY "Users can manage own posts" ON community_posts
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 2. Community Comments (Yorumlar)
CREATE TABLE community_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  parent_id uuid REFERENCES community_comments(id) ON DELETE CASCADE,
  content text NOT NULL,
  like_count int NOT NULL DEFAULT 0,
  is_reported boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  is_deleted boolean NOT NULL DEFAULT false
);

CREATE INDEX idx_community_comments_post ON community_comments(post_id);
CREATE INDEX idx_community_comments_user ON community_comments(user_id);
CREATE INDEX idx_community_comments_parent ON community_comments(parent_id);

ALTER TABLE community_comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view comments on public posts" ON community_comments
  FOR SELECT USING (is_deleted = false);
CREATE POLICY "Users can manage own comments" ON community_comments
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 3. Community Likes (Beğeniler)
CREATE TABLE community_likes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(post_id, user_id)
);

CREATE INDEX idx_community_likes_post ON community_likes(post_id);
CREATE INDEX idx_community_likes_user ON community_likes(user_id);

ALTER TABLE community_likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view likes" ON community_likes FOR SELECT USING (true);
CREATE POLICY "Users can manage own likes" ON community_likes
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 4. Community Comment Likes (Yorum beğenileri)
CREATE TABLE community_comment_likes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id uuid NOT NULL REFERENCES community_comments(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(comment_id, user_id)
);

CREATE INDEX idx_comment_likes_comment ON community_comment_likes(comment_id);

ALTER TABLE community_comment_likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view comment likes" ON community_comment_likes FOR SELECT USING (true);
CREATE POLICY "Users can manage own comment likes" ON community_comment_likes
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 5. Community Polls (Anketler)
CREATE TABLE community_polls (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE UNIQUE,
  question text NOT NULL,
  allow_multiple boolean NOT NULL DEFAULT false,
  ends_at timestamptz,
  total_votes int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE community_polls ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view polls" ON community_polls FOR SELECT USING (true);
CREATE POLICY "Users can create polls" ON community_polls
  FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM community_posts WHERE id = post_id AND user_id = auth.uid()));

-- 6. Community Poll Options (Anket seçenekleri)
CREATE TABLE community_poll_options (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id uuid NOT NULL REFERENCES community_polls(id) ON DELETE CASCADE,
  text text NOT NULL,
  vote_count int NOT NULL DEFAULT 0,
  sort_order int NOT NULL DEFAULT 0
);

CREATE INDEX idx_poll_options_poll ON community_poll_options(poll_id);

ALTER TABLE community_poll_options ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view poll options" ON community_poll_options FOR SELECT USING (true);

-- 7. Community Poll Votes (Anket oyları)
CREATE TABLE community_poll_votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id uuid NOT NULL REFERENCES community_polls(id) ON DELETE CASCADE,
  option_id uuid NOT NULL REFERENCES community_poll_options(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(poll_id, user_id, option_id)
);

CREATE INDEX idx_poll_votes_poll ON community_poll_votes(poll_id);

ALTER TABLE community_poll_votes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view vote counts" ON community_poll_votes FOR SELECT USING (true);
CREATE POLICY "Users can manage own votes" ON community_poll_votes
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 8. Community Bookmarks (Kaydedilen gönderiler)
CREATE TABLE community_bookmarks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(post_id, user_id)
);

CREATE INDEX idx_bookmarks_user ON community_bookmarks(user_id);

ALTER TABLE community_bookmarks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own bookmarks" ON community_bookmarks
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 9. Community Stories (24 saatlik hikayeler)
CREATE TABLE community_stories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  media_url text NOT NULL,
  media_type text NOT NULL DEFAULT 'image' CHECK (media_type IN ('image', 'video')),
  caption text,
  view_count int NOT NULL DEFAULT 0,
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '24 hours'),
  created_at timestamptz DEFAULT now(),
  is_deleted boolean NOT NULL DEFAULT false
);

CREATE INDEX idx_stories_user ON community_stories(user_id);
CREATE INDEX idx_stories_expires ON community_stories(expires_at);

ALTER TABLE community_stories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view active stories" ON community_stories
  FOR SELECT USING (expires_at > now() AND is_deleted = false);
CREATE POLICY "Users can manage own stories" ON community_stories
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 10. Community Story Views (Hikaye görüntülenmeleri)
CREATE TABLE community_story_views (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id uuid NOT NULL REFERENCES community_stories(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  viewed_at timestamptz DEFAULT now(),
  UNIQUE(story_id, user_id)
);

CREATE INDEX idx_story_views_story ON community_story_views(story_id);

ALTER TABLE community_story_views ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Story owners can view who watched" ON community_story_views
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM community_stories WHERE id = story_id AND user_id = auth.uid())
    OR auth.uid() = user_id
  );
CREATE POLICY "Users can insert own views" ON community_story_views
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 11. Community Events (Topluluk etkinlikleri)
CREATE TABLE community_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  event_date timestamptz NOT NULL,
  end_date timestamptz,
  location text,
  image_url text,
  max_attendees int,
  attendee_count int NOT NULL DEFAULT 0,
  event_type text NOT NULL DEFAULT 'meetup' CHECK (event_type IN ('meetup', 'exhibition', 'workshop', 'online', 'other')),
  status text NOT NULL DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'ongoing', 'completed', 'cancelled')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  is_deleted boolean NOT NULL DEFAULT false
);

CREATE INDEX idx_community_events_date ON community_events(event_date);

ALTER TABLE community_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view events" ON community_events
  FOR SELECT USING (is_deleted = false);
CREATE POLICY "Users can manage own events" ON community_events
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 12. Community Event Attendees (Etkinlik katılımcıları)
CREATE TABLE community_event_attendees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES community_events(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'going' CHECK (status IN ('going', 'interested', 'not_going')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(event_id, user_id)
);

CREATE INDEX idx_event_attendees_event ON community_event_attendees(event_id);

ALTER TABLE community_event_attendees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view attendees" ON community_event_attendees FOR SELECT USING (true);
CREATE POLICY "Users can manage own attendance" ON community_event_attendees
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
;
