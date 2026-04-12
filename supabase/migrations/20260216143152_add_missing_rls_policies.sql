
-- ============================================================
-- Migration: Add missing RLS policies
-- Fixes: Tables with RLS enabled but missing INSERT/UPDATE/DELETE policies
-- ============================================================

-- 1. notification_history: Add INSERT for users (to record sent notifications)
CREATE POLICY "Users can insert own notification history"
  ON notification_history FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- 2. notification_rate_limits: Add INSERT and UPDATE for users
CREATE POLICY "Users can insert own rate limits"
  ON notification_rate_limits FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own rate limits"
  ON notification_rate_limits FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- 3. admin_rate_limits: Add INSERT, UPDATE, DELETE for admins
CREATE POLICY "Admins can insert rate limits"
  ON admin_rate_limits FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = admin_user_id);

CREATE POLICY "Admins can update own rate limits"
  ON admin_rate_limits FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = admin_user_id);

CREATE POLICY "Admins can delete own rate limits"
  ON admin_rate_limits FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = admin_user_id);

-- 4. system_metrics: Add INSERT for admins (to write metrics)
CREATE POLICY "Admins can insert metrics"
  ON system_metrics FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users));

-- 5. deleted_eggs: Add DELETE for users (to clean up records)
CREATE POLICY "Users can delete own deleted egg records"
  ON deleted_eggs FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);
;
