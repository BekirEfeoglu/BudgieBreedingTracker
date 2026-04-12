-- =============================================================================
-- RLS Hardening: is_admin() Consistency, FORCE RLS, Vote Privacy
-- =============================================================================
-- 1. Update is_admin() to use (select auth.uid()) internally
-- 2. Replace all direct admin_users subqueries with is_admin() calls
-- 3. Add FORCE ROW LEVEL SECURITY to all 71 tables
-- 4. Restrict community_poll_votes SELECT for vote privacy
-- =============================================================================


-- =====================================================================
-- SECTION 1: Update is_admin() function — use (select auth.uid())
-- =====================================================================

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE user_id = (SELECT auth.uid())
      AND role = 'admin'
      AND is_deleted = FALSE
  );
END;
$$;


-- =====================================================================
-- SECTION 2: Replace admin_users subqueries with is_admin()
-- =====================================================================

-- -------------------------------------------------------------------
-- 2a. Entity table SELECT policies (13 tables)
--     Pattern: user owns OR admin → user owns OR is_admin()
-- -------------------------------------------------------------------

-- eggs
DROP POLICY IF EXISTS "Users can view own eggs" ON eggs;
CREATE POLICY "Users can view own eggs" ON eggs
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

-- chicks
DROP POLICY IF EXISTS "Users can view own chicks" ON chicks;
CREATE POLICY "Users can view own chicks" ON chicks
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

-- health_records
DROP POLICY IF EXISTS "Users can view own health_records" ON health_records;
CREATE POLICY "Users can view own health_records" ON health_records
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

-- growth_measurements
DROP POLICY IF EXISTS "Users can view own growth_measurements" ON growth_measurements;
CREATE POLICY "Users can view own growth_measurements" ON growth_measurements
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

-- events
DROP POLICY IF EXISTS "Users can view own events" ON events;
CREATE POLICY "Users can view own events" ON events
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

-- incubations
DROP POLICY IF EXISTS "Users can view own incubations" ON incubations;
CREATE POLICY "Users can view own incubations" ON incubations
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

-- clutches
DROP POLICY IF EXISTS "Users can view own clutches" ON clutches;
CREATE POLICY "Users can view own clutches" ON clutches
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

-- nests
DROP POLICY IF EXISTS "Users can view own nests" ON nests;
CREATE POLICY "Users can view own nests" ON nests
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

-- photos
DROP POLICY IF EXISTS "Users can view own photos" ON photos;
CREATE POLICY "Users can view own photos" ON photos
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

-- notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications" ON notifications
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

-- notification_settings
DROP POLICY IF EXISTS "Users can view own notification_settings" ON notification_settings;
CREATE POLICY "Users can view own notification_settings" ON notification_settings
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

-- notification_history
DROP POLICY IF EXISTS "Users can view own history" ON notification_history;
CREATE POLICY "Users can view own history" ON notification_history
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

-- notification_schedules
DROP POLICY IF EXISTS "Users can view own schedules" ON notification_schedules;
CREATE POLICY "Users can view own schedules" ON notification_schedules
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

-- -------------------------------------------------------------------
-- 2b. profiles — SELECT and UPDATE
-- -------------------------------------------------------------------

DROP POLICY IF EXISTS "profiles_select" ON profiles;
CREATE POLICY "profiles_select" ON profiles
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = id) OR (SELECT public.is_admin()));

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE TO authenticated
  USING (
    ((SELECT auth.uid()) = id)
    OR (SELECT public.is_admin())
  )
  WITH CHECK (
    -- Admins can update any field on any profile
    (SELECT public.is_admin())
    OR
    -- Regular users can only update their own profile,
    -- but cannot change sensitive fields (is_premium, role, subscription_status, is_active)
    (
      ((SELECT auth.uid()) = id)
      AND (is_premium = (SELECT p.is_premium FROM profiles p WHERE p.id = (SELECT auth.uid())))
      AND (NOT (role IS DISTINCT FROM (SELECT p.role FROM profiles p WHERE p.id = (SELECT auth.uid()))))
      AND (subscription_status = (SELECT p.subscription_status FROM profiles p WHERE p.id = (SELECT auth.uid())))
      AND (is_active = (SELECT p.is_active FROM profiles p WHERE p.id = (SELECT auth.uid())))
    )
  );

-- -------------------------------------------------------------------
-- 2c. admin_logs — SELECT, INSERT, UPDATE, DELETE
-- -------------------------------------------------------------------

DROP POLICY IF EXISTS "admin_logs_select" ON admin_logs;
CREATE POLICY "admin_logs_select" ON admin_logs
  FOR SELECT TO authenticated
  USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "admin_logs_insert" ON admin_logs;
CREATE POLICY "admin_logs_insert" ON admin_logs
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "admin_logs_update" ON admin_logs;
CREATE POLICY "admin_logs_update" ON admin_logs
  FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin()))
  WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "admin_logs_delete" ON admin_logs;
CREATE POLICY "admin_logs_delete" ON admin_logs
  FOR DELETE TO authenticated
  USING ((SELECT public.is_admin()));

-- -------------------------------------------------------------------
-- 2d. admin_sessions — ownership via admin_user_id FK (keep admin_users ref)
--     Justified: admin_sessions.admin_user_id references admin_users.id,
--     so FK lookup is required for row ownership, not just permission.
-- -------------------------------------------------------------------
-- No change needed — ownership check is FK-based, not permission-based.

-- -------------------------------------------------------------------
-- 2e. system_alerts — admin-only FOR ALL
-- -------------------------------------------------------------------

DROP POLICY IF EXISTS "system_alerts_all" ON system_alerts;
CREATE POLICY "system_alerts_all" ON system_alerts
  FOR ALL TO authenticated
  USING ((SELECT public.is_admin()))
  WITH CHECK ((SELECT public.is_admin()));

-- -------------------------------------------------------------------
-- 2f. system_metrics — admin SELECT + INSERT
-- -------------------------------------------------------------------

DROP POLICY IF EXISTS "system_metrics_select" ON system_metrics;
CREATE POLICY "system_metrics_select" ON system_metrics
  FOR SELECT TO authenticated
  USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "Admins can insert metrics" ON system_metrics;
CREATE POLICY "Admins can insert metrics" ON system_metrics
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_admin()));

-- -------------------------------------------------------------------
-- 2g. system_status — admin FOR ALL (user SELECT stays untouched)
-- -------------------------------------------------------------------

DROP POLICY IF EXISTS "system_status_all" ON system_status;
CREATE POLICY "system_status_all" ON system_status
  FOR ALL TO authenticated
  USING ((SELECT public.is_admin()))
  WITH CHECK ((SELECT public.is_admin()));

-- -------------------------------------------------------------------
-- 2h. system_settings — user view + admin CRUD
-- -------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view settings" ON system_settings;
CREATE POLICY "Users can view settings" ON system_settings
  FOR SELECT TO authenticated
  USING (is_public = true OR (SELECT public.is_admin()));

DROP POLICY IF EXISTS "Admins can insert settings" ON system_settings;
CREATE POLICY "Admins can insert settings" ON system_settings
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "Admins can update settings" ON system_settings;
CREATE POLICY "Admins can update settings" ON system_settings
  FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin()))
  WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "Admins can delete settings" ON system_settings;
CREATE POLICY "Admins can delete settings" ON system_settings
  FOR DELETE TO authenticated
  USING ((SELECT public.is_admin()));

-- -------------------------------------------------------------------
-- 2i. error_logs — admin SELECT/UPDATE/DELETE
-- -------------------------------------------------------------------

DROP POLICY IF EXISTS "Admins can view error logs" ON error_logs;
CREATE POLICY "Admins can view error logs" ON error_logs
  FOR SELECT TO authenticated
  USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "Admins can update error logs" ON error_logs;
CREATE POLICY "Admins can update error logs" ON error_logs
  FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin()))
  WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "Admins can delete error logs" ON error_logs;
CREATE POLICY "Admins can delete error logs" ON error_logs
  FOR DELETE TO authenticated
  USING ((SELECT public.is_admin()));

-- -------------------------------------------------------------------
-- 2j. security_events — combined SELECT + admin UPDATE/DELETE
-- -------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view security events" ON security_events;
CREATE POLICY "Users can view security events" ON security_events
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

DROP POLICY IF EXISTS "Admins can update security events" ON security_events;
CREATE POLICY "Admins can update security events" ON security_events
  FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin()))
  WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "Admins can delete security events" ON security_events;
CREATE POLICY "Admins can delete security events" ON security_events
  FOR DELETE TO authenticated
  USING ((SELECT public.is_admin()));

-- -------------------------------------------------------------------
-- 2k. user_subscriptions — admin INSERT/UPDATE
-- -------------------------------------------------------------------

DROP POLICY IF EXISTS "Admins can insert subscriptions" ON user_subscriptions;
CREATE POLICY "Admins can insert subscriptions" ON user_subscriptions
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "Admins can update subscriptions" ON user_subscriptions;
CREATE POLICY "Admins can update subscriptions" ON user_subscriptions
  FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin()))
  WITH CHECK ((SELECT public.is_admin()));

-- -------------------------------------------------------------------
-- 2l. feedback — combined user+admin SELECT
-- -------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view feedback" ON feedback;
CREATE POLICY "Users can view feedback" ON feedback
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));

-- -------------------------------------------------------------------
-- 2m. privacy_audit_logs — combined user+admin SELECT
-- -------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view privacy logs" ON privacy_audit_logs;
CREATE POLICY "Users can view privacy logs" ON privacy_audit_logs
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));


-- =====================================================================
-- SECTION 3: FORCE ROW LEVEL SECURITY on all 71 tables
-- =====================================================================
-- Defense-in-depth: ensures even table owners respect RLS policies.
-- Idempotent — harmless if already forced.

-- Core breeding domain (11)
ALTER TABLE profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE birds FORCE ROW LEVEL SECURITY;
ALTER TABLE breeding_pairs FORCE ROW LEVEL SECURITY;
ALTER TABLE incubations FORCE ROW LEVEL SECURITY;
ALTER TABLE eggs FORCE ROW LEVEL SECURITY;
ALTER TABLE chicks FORCE ROW LEVEL SECURITY;
ALTER TABLE health_records FORCE ROW LEVEL SECURITY;
ALTER TABLE growth_measurements FORCE ROW LEVEL SECURITY;
ALTER TABLE events FORCE ROW LEVEL SECURITY;
ALTER TABLE notifications FORCE ROW LEVEL SECURITY;
ALTER TABLE notification_settings FORCE ROW LEVEL SECURITY;

-- Extended domain (4)
ALTER TABLE clutches FORCE ROW LEVEL SECURITY;
ALTER TABLE nests FORCE ROW LEVEL SECURITY;
ALTER TABLE photos FORCE ROW LEVEL SECURITY;
ALTER TABLE deleted_eggs FORCE ROW LEVEL SECURITY;

-- User & subscription (5)
ALTER TABLE user_preferences FORCE ROW LEVEL SECURITY;
ALTER TABLE user_sessions FORCE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans FORCE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions FORCE ROW LEVEL SECURITY;
ALTER TABLE feedback FORCE ROW LEVEL SECURITY;

-- Calendar & events (4)
ALTER TABLE calendar FORCE ROW LEVEL SECURITY;
ALTER TABLE event_types FORCE ROW LEVEL SECURITY;
ALTER TABLE event_templates FORCE ROW LEVEL SECURITY;
ALTER TABLE event_reminders FORCE ROW LEVEL SECURITY;

-- Notification system (5)
ALTER TABLE notification_schedules FORCE ROW LEVEL SECURITY;
ALTER TABLE fcm_tokens FORCE ROW LEVEL SECURITY;
ALTER TABLE web_push_subscriptions FORCE ROW LEVEL SECURITY;
ALTER TABLE notification_history FORCE ROW LEVEL SECURITY;
ALTER TABLE notification_rate_limits FORCE ROW LEVEL SECURITY;

-- Community (14)
ALTER TABLE community_posts FORCE ROW LEVEL SECURITY;
ALTER TABLE community_comments FORCE ROW LEVEL SECURITY;
ALTER TABLE community_likes FORCE ROW LEVEL SECURITY;
ALTER TABLE community_comment_likes FORCE ROW LEVEL SECURITY;
ALTER TABLE community_polls FORCE ROW LEVEL SECURITY;
ALTER TABLE community_poll_options FORCE ROW LEVEL SECURITY;
ALTER TABLE community_poll_votes FORCE ROW LEVEL SECURITY;
ALTER TABLE community_bookmarks FORCE ROW LEVEL SECURITY;
ALTER TABLE community_stories FORCE ROW LEVEL SECURITY;
ALTER TABLE community_story_views FORCE ROW LEVEL SECURITY;
ALTER TABLE community_events FORCE ROW LEVEL SECURITY;
ALTER TABLE community_event_attendees FORCE ROW LEVEL SECURITY;
ALTER TABLE community_follows FORCE ROW LEVEL SECURITY;
ALTER TABLE community_reports FORCE ROW LEVEL SECURITY;

-- Archive (8)
ALTER TABLE archived_birds FORCE ROW LEVEL SECURITY;
ALTER TABLE archived_breeding_pairs FORCE ROW LEVEL SECURITY;
ALTER TABLE archived_clutches FORCE ROW LEVEL SECURITY;
ALTER TABLE archived_eggs FORCE ROW LEVEL SECURITY;
ALTER TABLE archived_chicks FORCE ROW LEVEL SECURITY;
ALTER TABLE archive_jobs FORCE ROW LEVEL SECURITY;
ALTER TABLE archive_settings FORCE ROW LEVEL SECURITY;
ALTER TABLE egg_archives FORCE ROW LEVEL SECURITY;

-- Security & privacy (3)
ALTER TABLE privacy_settings FORCE ROW LEVEL SECURITY;
ALTER TABLE privacy_audit_logs FORCE ROW LEVEL SECURITY;
ALTER TABLE security_events FORCE ROW LEVEL SECURITY;

-- Admin & system (8)
ALTER TABLE admin_users FORCE ROW LEVEL SECURITY;
ALTER TABLE admin_logs FORCE ROW LEVEL SECURITY;
ALTER TABLE admin_sessions FORCE ROW LEVEL SECURITY;
ALTER TABLE admin_rate_limits FORCE ROW LEVEL SECURITY;
ALTER TABLE system_settings FORCE ROW LEVEL SECURITY;
ALTER TABLE system_metrics FORCE ROW LEVEL SECURITY;
ALTER TABLE system_status FORCE ROW LEVEL SECURITY;
ALTER TABLE system_alerts FORCE ROW LEVEL SECURITY;
ALTER TABLE error_logs FORCE ROW LEVEL SECURITY;

-- Backup (4)
ALTER TABLE backup_history FORCE ROW LEVEL SECURITY;
ALTER TABLE backup_jobs FORCE ROW LEVEL SECURITY;
ALTER TABLE backup_settings FORCE ROW LEVEL SECURITY;
ALTER TABLE config_backups FORCE ROW LEVEL SECURITY;

-- Standalone (5)
ALTER TABLE sync_metadata FORCE ROW LEVEL SECURITY;
ALTER TABLE genetics_history FORCE ROW LEVEL SECURITY;
ALTER TABLE audit_logs FORCE ROW LEVEL SECURITY;
ALTER TABLE mfa_lockouts FORCE ROW LEVEL SECURITY;


-- =====================================================================
-- SECTION 4: community_poll_votes — vote privacy
-- =====================================================================
-- Replace USING (true) public SELECT with own-votes-only + admin.
-- Aggregated vote counts should be fetched via an RPC if needed.

DROP POLICY IF EXISTS "Anyone can view vote counts" ON community_poll_votes;
CREATE POLICY "Users can view own votes" ON community_poll_votes
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR (SELECT public.is_admin()));
