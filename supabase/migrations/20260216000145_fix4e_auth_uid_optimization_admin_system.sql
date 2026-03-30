
-- Fix 4e: Replace auth.uid() with (select auth.uid()) for admin/system tables

-- ========== ADMIN_USERS ==========
DROP POLICY IF EXISTS "Admin users can read admin list" ON admin_users;
CREATE POLICY "Admin users can read admin list" ON admin_users FOR SELECT TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));

-- ========== ADMIN_LOGS ==========
DROP POLICY IF EXISTS "Admins can view logs" ON admin_logs;
DROP POLICY IF EXISTS "Admins can insert logs" ON admin_logs;
CREATE POLICY "Admins can view logs" ON admin_logs FOR SELECT TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));
CREATE POLICY "Admins can insert logs" ON admin_logs FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) IN (SELECT user_id FROM admin_users));

-- ========== ADMIN_SESSIONS ==========
DROP POLICY IF EXISTS "Admins can manage own sessions" ON admin_sessions;
CREATE POLICY "Admins can manage own sessions" ON admin_sessions FOR ALL TO authenticated
  USING (admin_user_id IN (
    SELECT id FROM admin_users WHERE user_id = (select auth.uid())
  ));

-- ========== ADMIN_RATE_LIMITS ==========
DROP POLICY IF EXISTS "Admins can view own rate limits" ON admin_rate_limits;
CREATE POLICY "Admins can view own rate limits" ON admin_rate_limits FOR SELECT TO authenticated
  USING ((select auth.uid()) = admin_user_id);

-- ========== ERROR_LOGS ==========
DROP POLICY IF EXISTS "Admins can manage error logs" ON error_logs;
-- Note: "Users can insert own errors" was already created with (select auth.uid()) in fix3
CREATE POLICY "Admins can manage error logs" ON error_logs FOR ALL TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));

-- ========== SECURITY_EVENTS ==========
DROP POLICY IF EXISTS "Admins can view all security events" ON security_events;
DROP POLICY IF EXISTS "Users can view own security events" ON security_events;
-- Note: "Users can insert own security events" was already created with (select auth.uid()) in fix3
CREATE POLICY "Admins can view all security events" ON security_events FOR SELECT TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));
CREATE POLICY "Users can view own security events" ON security_events FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== SYSTEM_SETTINGS ==========
DROP POLICY IF EXISTS "Admins can manage all settings" ON system_settings;
CREATE POLICY "Admins can manage all settings" ON system_settings FOR ALL TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));

-- ========== SYSTEM_METRICS ==========
DROP POLICY IF EXISTS "Admins can view metrics" ON system_metrics;
CREATE POLICY "Admins can view metrics" ON system_metrics FOR SELECT TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));

-- ========== SYSTEM_STATUS ==========
DROP POLICY IF EXISTS "Admins can manage status" ON system_status;
CREATE POLICY "Admins can manage status" ON system_status FOR ALL TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));

-- ========== SYSTEM_ALERTS ==========
DROP POLICY IF EXISTS "Admins can manage alerts" ON system_alerts;
CREATE POLICY "Admins can manage alerts" ON system_alerts FOR ALL TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));
;
