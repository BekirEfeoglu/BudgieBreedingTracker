
-- ============================================================
-- Migration: Drop redundant indexes
-- Fixes: unused_index warnings
-- Reason: UNIQUE constraints already create implicit btree indexes.
--         A separate regular index on the same leading column(s) is redundant.
-- ============================================================

-- 1. admin_users: user_id already has UNIQUE index via admin_users_user_id_key
DROP INDEX IF EXISTS idx_admin_users_user_id;

-- 2. user_preferences: user_id already has UNIQUE index via user_preferences_user_id_key
DROP INDEX IF EXISTS idx_user_preferences_user_id;

-- 3. notification_settings: user_id already has UNIQUE index via idx_notification_settings_user_unique
DROP INDEX IF EXISTS idx_notification_settings_user_id;

-- 4. community_comment_likes: comment_id is leading column in
--    community_comment_likes_comment_id_user_id_key (UNIQUE composite)
DROP INDEX IF EXISTS idx_comment_likes_comment;

-- 5. community_likes: post_id is leading column in
--    community_likes_post_id_user_id_key (UNIQUE composite)
DROP INDEX IF EXISTS idx_community_likes_post;

-- 6. community_poll_votes: poll_id is leading column in
--    community_poll_votes_poll_id_user_id_option_id_key (UNIQUE composite)
DROP INDEX IF EXISTS idx_poll_votes_poll;

-- 7. community_story_views: story_id is leading column in
--    community_story_views_story_id_user_id_key (UNIQUE composite)
DROP INDEX IF EXISTS idx_story_views_story;

-- 8. community_event_attendees: event_id is leading column in
--    community_event_attendees_event_id_user_id_key (UNIQUE composite)
DROP INDEX IF EXISTS idx_event_attendees_event;
;
