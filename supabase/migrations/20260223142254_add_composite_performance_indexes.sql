
-- ================================================================
-- Composite performance indexes for Supabase PostgreSQL
-- Two critical query patterns:
--   1. fetchAll:          WHERE user_id = ? AND is_deleted = false
--   2. fetchUpdatedSince: WHERE user_id = ? AND updated_at >= ?
-- ================================================================

-- === (user_id, is_deleted) for fetchAll — 11 tables ===
CREATE INDEX IF NOT EXISTS idx_birds_user_deleted ON birds(user_id, is_deleted);
CREATE INDEX IF NOT EXISTS idx_eggs_user_deleted ON eggs(user_id, is_deleted);
CREATE INDEX IF NOT EXISTS idx_chicks_user_deleted ON chicks(user_id, is_deleted);
CREATE INDEX IF NOT EXISTS idx_breeding_pairs_user_deleted ON breeding_pairs(user_id, is_deleted);
CREATE INDEX IF NOT EXISTS idx_clutches_user_deleted ON clutches(user_id, is_deleted);
CREATE INDEX IF NOT EXISTS idx_events_user_deleted ON events(user_id, is_deleted);
CREATE INDEX IF NOT EXISTS idx_health_records_user_deleted ON health_records(user_id, is_deleted);
CREATE INDEX IF NOT EXISTS idx_nests_user_deleted ON nests(user_id, is_deleted);
CREATE INDEX IF NOT EXISTS idx_photos_user_deleted ON photos(user_id, is_deleted);
CREATE INDEX IF NOT EXISTS idx_event_reminders_user_deleted ON event_reminders(user_id, is_deleted);
CREATE INDEX IF NOT EXISTS idx_calendar_user_deleted ON calendar(user_id, is_deleted);

-- === (user_id, updated_at) for fetchUpdatedSince — 16 syncable tables ===
CREATE INDEX IF NOT EXISTS idx_birds_user_updated ON birds(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_eggs_user_updated ON eggs(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_chicks_user_updated ON chicks(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_breeding_pairs_user_updated ON breeding_pairs(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_clutches_user_updated ON clutches(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_incubations_user_updated ON incubations(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_nests_user_updated ON nests(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_events_user_updated ON events(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_notifications_user_updated ON notifications(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_notification_schedules_user_updated ON notification_schedules(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_health_records_user_updated ON health_records(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_growth_measurements_user_updated ON growth_measurements(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_photos_user_updated ON photos(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_feedback_user_updated ON feedback(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_event_reminders_user_updated ON event_reminders(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_calendar_user_updated ON calendar(user_id, updated_at);

-- === sync_metadata composite indexes ===
CREATE INDEX IF NOT EXISTS idx_sync_meta_table_status ON sync_metadata(table_name, status);
CREATE INDEX IF NOT EXISTS idx_sync_meta_user_table_status ON sync_metadata(user_id, table_name, status);
;
