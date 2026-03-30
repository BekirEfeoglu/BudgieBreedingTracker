
-- ============================================================
-- FIX: Drop ALL problematic policies and recreate them cleanly
-- The root cause: admin_users has a self-referencing policy
-- ============================================================

-- 1) Drop ALL existing policies on admin_users
DROP POLICY IF EXISTS "Admin users can read" ON admin_users;
DROP POLICY IF EXISTS "Admin users can read admin list" ON admin_users;
DROP POLICY IF EXISTS "Admin users can read own record" ON admin_users;

-- 2) Create clean, non-recursive policy on admin_users
-- Each admin can only see their own row (no self-reference)
CREATE POLICY "admin_users_select_own"
  ON admin_users FOR SELECT
  USING (auth.uid() = user_id);

-- 3) Fix profiles: drop merged policy and recreate correctly
DROP POLICY IF EXISTS "Users can view profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;

-- Users can see own profile OR admins can see all profiles
-- This is safe because admin_users policy is now non-recursive
CREATE POLICY "profiles_select"
  ON profiles FOR SELECT
  USING (
    auth.uid() = id
    OR auth.uid() IN (SELECT user_id FROM admin_users)
  );

-- 4) Fix other admin tables that reference admin_users
-- These were already correct but let's ensure clean state

-- admin_logs
DROP POLICY IF EXISTS "Admins can view logs" ON admin_logs;
CREATE POLICY "admin_logs_select"
  ON admin_logs FOR SELECT
  USING (auth.uid() IN (SELECT user_id FROM admin_users));

DROP POLICY IF EXISTS "Admins can insert logs" ON admin_logs;
CREATE POLICY "admin_logs_insert"
  ON admin_logs FOR INSERT
  WITH CHECK (auth.uid() IN (SELECT user_id FROM admin_users));

-- security_events: keep user-own + admin-all
DROP POLICY IF EXISTS "Admins can view all security events" ON security_events;
DROP POLICY IF EXISTS "Users can view own security events" ON security_events;
CREATE POLICY "security_events_select"
  ON security_events FOR SELECT
  USING (
    auth.uid() = user_id
    OR auth.uid() IN (SELECT user_id FROM admin_users)
  );

-- system_settings
DROP POLICY IF EXISTS "Admins can manage all settings" ON system_settings;
DROP POLICY IF EXISTS "Anyone can view public settings" ON system_settings;
CREATE POLICY "system_settings_select"
  ON system_settings FOR SELECT
  USING (
    is_public = true
    OR auth.uid() IN (SELECT user_id FROM admin_users)
  );
CREATE POLICY "system_settings_modify"
  ON system_settings FOR ALL
  USING (auth.uid() IN (SELECT user_id FROM admin_users))
  WITH CHECK (auth.uid() IN (SELECT user_id FROM admin_users));

-- system_alerts
DROP POLICY IF EXISTS "Admins can manage alerts" ON system_alerts;
CREATE POLICY "system_alerts_all"
  ON system_alerts FOR ALL
  USING (auth.uid() IN (SELECT user_id FROM admin_users))
  WITH CHECK (auth.uid() IN (SELECT user_id FROM admin_users));

-- system_metrics
DROP POLICY IF EXISTS "Admins can view metrics" ON system_metrics;
CREATE POLICY "system_metrics_select"
  ON system_metrics FOR SELECT
  USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- system_status
DROP POLICY IF EXISTS "Admins can manage status" ON system_status;
CREATE POLICY "system_status_all"
  ON system_status FOR ALL
  USING (auth.uid() IN (SELECT user_id FROM admin_users))
  WITH CHECK (auth.uid() IN (SELECT user_id FROM admin_users));

-- admin_sessions
DROP POLICY IF EXISTS "Admins can manage own sessions" ON admin_sessions;
CREATE POLICY "admin_sessions_all"
  ON admin_sessions FOR ALL
  USING (admin_user_id IN (SELECT id FROM admin_users WHERE user_id = auth.uid()))
  WITH CHECK (admin_user_id IN (SELECT id FROM admin_users WHERE user_id = auth.uid()));

-- 5) Fix user-facing tables for admin read access
-- user_sessions
DROP POLICY IF EXISTS "Admins can view all sessions" ON user_sessions;
DROP POLICY IF EXISTS "Users can manage own sessions" ON user_sessions;
CREATE POLICY "user_sessions_own"
  ON user_sessions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_sessions_admin_select"
  ON user_sessions FOR SELECT
  USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- user_subscriptions
DROP POLICY IF EXISTS "Admins can view all subscriptions" ON user_subscriptions;
DROP POLICY IF EXISTS "Users can view own subscriptions" ON user_subscriptions;
CREATE POLICY "user_subscriptions_select"
  ON user_subscriptions FOR SELECT
  USING (
    auth.uid() = user_id
    OR auth.uid() IN (SELECT user_id FROM admin_users)
  );

-- birds (admin read)
DROP POLICY IF EXISTS "Admins can view all birds" ON birds;
-- Keep existing user policies, just add admin read
CREATE POLICY "birds_admin_select"
  ON birds FOR SELECT
  USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- breeding_pairs (admin read)
DROP POLICY IF EXISTS "Admins can view all breeding pairs" ON breeding_pairs;
CREATE POLICY "breeding_pairs_admin_select"
  ON breeding_pairs FOR SELECT
  USING (auth.uid() IN (SELECT user_id FROM admin_users));
;
