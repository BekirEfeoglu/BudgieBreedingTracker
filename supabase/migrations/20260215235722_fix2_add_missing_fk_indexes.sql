
-- =============================================
-- FIX 2: Missing FK indexes (unindexed_foreign_keys)
-- Indexes on FK columns for fast JOINs and CASCADE deletes
-- =============================================

-- Core domain FKs
CREATE INDEX IF NOT EXISTS idx_chicks_egg_id ON chicks(egg_id);
CREATE INDEX IF NOT EXISTS idx_chicks_bird_id ON chicks(bird_id);
CREATE INDEX IF NOT EXISTS idx_eggs_clutch_id ON eggs(clutch_id);
CREATE INDEX IF NOT EXISTS idx_incubations_clutch_id ON incubations(clutch_id);
CREATE INDEX IF NOT EXISTS idx_events_bird_id ON events(bird_id);
CREATE INDEX IF NOT EXISTS idx_events_breeding_pair_id ON events(breeding_pair_id);

-- Deleted eggs
CREATE INDEX IF NOT EXISTS idx_deleted_eggs_deleted_by ON deleted_eggs(deleted_by);

-- Notification history
CREATE INDEX IF NOT EXISTS idx_notification_history_notification_id ON notification_history(notification_id);
CREATE INDEX IF NOT EXISTS idx_notification_history_schedule_id ON notification_history(schedule_id);

-- Event reminders
CREATE INDEX IF NOT EXISTS idx_event_reminders_calendar_id ON event_reminders(calendar_id);

-- Event templates
CREATE INDEX IF NOT EXISTS idx_event_templates_event_type_id ON event_templates(event_type_id);

-- Community
CREATE INDEX IF NOT EXISTS idx_community_events_user_id ON community_events(user_id);
CREATE INDEX IF NOT EXISTS idx_community_comment_likes_user_id ON community_comment_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_community_event_attendees_user_id ON community_event_attendees(user_id);
CREATE INDEX IF NOT EXISTS idx_community_poll_votes_option_id ON community_poll_votes(option_id);
CREATE INDEX IF NOT EXISTS idx_community_poll_votes_user_id ON community_poll_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_community_story_views_user_id ON community_story_views(user_id);

-- Archive tables
CREATE INDEX IF NOT EXISTS idx_archived_birds_archived_by ON archived_birds(archived_by);
CREATE INDEX IF NOT EXISTS idx_archived_breeding_pairs_archived_by ON archived_breeding_pairs(archived_by);
CREATE INDEX IF NOT EXISTS idx_archived_clutches_archived_by ON archived_clutches(archived_by);
CREATE INDEX IF NOT EXISTS idx_archived_eggs_archived_by ON archived_eggs(archived_by);
CREATE INDEX IF NOT EXISTS idx_archived_chicks_archived_by ON archived_chicks(archived_by);

-- Backup
CREATE INDEX IF NOT EXISTS idx_backup_jobs_source_backup ON backup_jobs(source_backup_id);

-- User subscriptions
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_plan_id ON user_subscriptions(plan_id);

-- Error logs
CREATE INDEX IF NOT EXISTS idx_error_logs_user_id ON error_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_error_logs_resolved_by ON error_logs(resolved_by);

-- Security events
CREATE INDEX IF NOT EXISTS idx_security_events_resolved_by ON security_events(resolved_by);

-- System
CREATE INDEX IF NOT EXISTS idx_system_alerts_acknowledged_by ON system_alerts(acknowledged_by);
CREATE INDEX IF NOT EXISTS idx_system_settings_updated_by ON system_settings(updated_by);
;
