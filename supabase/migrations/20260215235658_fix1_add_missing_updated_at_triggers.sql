
-- =============================================
-- FIX 1: Missing updated_at triggers on new tables
-- The update_updated_at() function already exists.
-- Add triggers for all tables that have updated_at but no trigger.
-- =============================================

-- Batch 1: Core Domain
CREATE TRIGGER update_clutches_updated_at BEFORE UPDATE ON clutches FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_nests_updated_at BEFORE UPDATE ON nests FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_photos_updated_at BEFORE UPDATE ON photos FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Batch 2: User & Subscription
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_user_subscriptions_updated_at BEFORE UPDATE ON user_subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_feedback_updated_at BEFORE UPDATE ON feedback FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_subscription_plans_updated_at BEFORE UPDATE ON subscription_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Batch 3: Calendar & Events
CREATE TRIGGER update_calendar_updated_at BEFORE UPDATE ON calendar FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_event_types_updated_at BEFORE UPDATE ON event_types FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_event_templates_updated_at BEFORE UPDATE ON event_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_event_reminders_updated_at BEFORE UPDATE ON event_reminders FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Batch 4: Notifications
CREATE TRIGGER update_notification_schedules_updated_at BEFORE UPDATE ON notification_schedules FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_fcm_tokens_updated_at BEFORE UPDATE ON fcm_tokens FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_web_push_subscriptions_updated_at BEFORE UPDATE ON web_push_subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_notification_rate_limits_updated_at BEFORE UPDATE ON notification_rate_limits FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Batch 5: Community
CREATE TRIGGER update_community_posts_updated_at BEFORE UPDATE ON community_posts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_community_comments_updated_at BEFORE UPDATE ON community_comments FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_community_events_updated_at BEFORE UPDATE ON community_events FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Batch 6: Archive
CREATE TRIGGER update_archive_settings_updated_at BEFORE UPDATE ON archive_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Batch 7: Security & Privacy
CREATE TRIGGER update_privacy_settings_updated_at BEFORE UPDATE ON privacy_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Batch 8: Admin & System
CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON admin_users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_backup_jobs_updated_at BEFORE UPDATE ON backup_jobs FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_backup_settings_updated_at BEFORE UPDATE ON backup_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_system_alerts_updated_at BEFORE UPDATE ON system_alerts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_system_status_updated_at BEFORE UPDATE ON system_status FOR EACH ROW EXECUTE FUNCTION update_updated_at();
;
