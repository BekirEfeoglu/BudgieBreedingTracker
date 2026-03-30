
-- ================================================================
-- Drop redundant single-column (user_id) indexes.
-- These are now covered by composite indexes:
--   (user_id, is_deleted) for fetchAll
--   (user_id, updated_at) for fetchUpdatedSince
-- PostgreSQL can use the leftmost column of a composite index
-- for single-column lookups, making these unnecessary.
-- ================================================================

DROP INDEX IF EXISTS idx_birds_user_id;
DROP INDEX IF EXISTS idx_breeding_pairs_user_id;
DROP INDEX IF EXISTS idx_calendar_user_id;
DROP INDEX IF EXISTS idx_chicks_user_id;
DROP INDEX IF EXISTS idx_clutches_user_id;
DROP INDEX IF EXISTS idx_eggs_user_id;
DROP INDEX IF EXISTS idx_event_reminders_user_id;
DROP INDEX IF EXISTS idx_events_user_id;
DROP INDEX IF EXISTS idx_feedback_user_id;
DROP INDEX IF EXISTS idx_growth_measurements_user_id;
DROP INDEX IF EXISTS idx_health_records_user_id;
DROP INDEX IF EXISTS idx_incubations_user_id;
DROP INDEX IF EXISTS idx_nests_user_id;
DROP INDEX IF EXISTS idx_notification_schedules_user_id;
DROP INDEX IF EXISTS idx_notifications_user_id;
DROP INDEX IF EXISTS idx_photos_user_id;
DROP INDEX IF EXISTS idx_sync_metadata_user_id;
;
