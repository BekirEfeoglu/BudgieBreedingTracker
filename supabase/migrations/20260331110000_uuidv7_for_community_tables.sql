-- =============================================
-- Migrate ALL table PK defaults from UUIDv4 to UUIDv7.
-- UUIDv7 is time-ordered, which means:
--   1. B-tree inserts are sequential (no random page splits / fragmentation)
--   2. Natural chronological ordering without extra index
--   3. Existing UUIDv4 rows remain valid (UUIDv7 is backward-compatible)
--
-- Note: Client-side Dart code also generates UUIDs; the matching Dart
-- change switches Uuid().v4() → Uuid().v7() across all repositories.
-- =============================================

-- Enable pg_uuidv7 extension (provides uuid_generate_v7 function).
-- Supabase supports this extension natively.
CREATE EXTENSION IF NOT EXISTS pg_uuidv7;

-- =============================================
-- Core domain tables
-- =============================================
ALTER TABLE birds
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE breeding_pairs
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE clutches
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE eggs
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE chicks
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE incubations
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE nests
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE events
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE health_records
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE growth_measurements
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE photos
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE deleted_eggs
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

-- =============================================
-- Notification & calendar tables
-- =============================================
ALTER TABLE notifications
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE notification_settings
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE notification_schedules
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE event_reminders
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE calendar
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

-- =============================================
-- User & system tables
-- =============================================
ALTER TABLE user_preferences
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE feedback
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE genetics_history
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE sync_metadata
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

-- =============================================
-- Community tables
-- =============================================
ALTER TABLE community_posts
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE community_comments
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE community_likes
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE community_comment_likes
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE community_polls
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE community_poll_options
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE community_poll_votes
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE community_bookmarks
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE community_stories
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE community_story_views
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE community_events
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE community_event_attendees
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE community_follows
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();

ALTER TABLE community_reports
  ALTER COLUMN id SET DEFAULT uuid_generate_v7();
