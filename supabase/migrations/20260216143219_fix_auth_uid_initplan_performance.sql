
-- ============================================================
-- Migration: Fix auth.uid() → (SELECT auth.uid()) for initplan optimization
-- Fixes: 16x auth_rls_initplan performance warnings
-- Pattern: (SELECT auth.uid()) evaluates ONCE per query instead of per-row
-- Strategy: DROP + CREATE to replace policies (ALTER POLICY can't change qual)
-- ============================================================

-- 1. admin_logs: Fix INSERT and SELECT
DROP POLICY IF EXISTS "admin_logs_insert" ON admin_logs;
CREATE POLICY "admin_logs_insert" ON admin_logs FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users));

DROP POLICY IF EXISTS "admin_logs_select" ON admin_logs;
CREATE POLICY "admin_logs_select" ON admin_logs FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users));

-- 2. admin_sessions: Fix ALL
DROP POLICY IF EXISTS "admin_sessions_all" ON admin_sessions;
CREATE POLICY "admin_sessions_all" ON admin_sessions FOR ALL TO authenticated
  USING (admin_user_id IN (SELECT id FROM admin_users WHERE user_id = (SELECT auth.uid())))
  WITH CHECK (admin_user_id IN (SELECT id FROM admin_users WHERE user_id = (SELECT auth.uid())));

-- 3. admin_users: Fix SELECT
DROP POLICY IF EXISTS "admin_users_select_own" ON admin_users;
CREATE POLICY "admin_users_select_own" ON admin_users FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- 4. profiles: Fix SELECT and UPDATE
DROP POLICY IF EXISTS "profiles_select" ON profiles;
CREATE POLICY "profiles_select" ON profiles FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = id) OR ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users)));

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = id);

-- 5. subscription_plans: Fix SELECT (keep public role for pricing page visibility)
DROP POLICY IF EXISTS "Anyone can view active plans" ON subscription_plans;
CREATE POLICY "Anyone can view active plans" ON subscription_plans FOR SELECT TO public
  USING (is_active = true);

-- 6. system_alerts: Fix ALL
DROP POLICY IF EXISTS "system_alerts_all" ON system_alerts;
CREATE POLICY "system_alerts_all" ON system_alerts FOR ALL TO authenticated
  USING ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users))
  WITH CHECK ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users));

-- 7. system_metrics: Fix SELECT
DROP POLICY IF EXISTS "system_metrics_select" ON system_metrics;
CREATE POLICY "system_metrics_select" ON system_metrics FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users));

-- 8. system_status: Fix ALL
DROP POLICY IF EXISTS "system_status_all" ON system_status;
CREATE POLICY "system_status_all" ON system_status FOR ALL TO authenticated
  USING ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users))
  WITH CHECK ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users));

-- 9. community_poll_options: Fix SELECT (keep public for visibility)
DROP POLICY IF EXISTS "Anyone can view poll options" ON community_poll_options;
CREATE POLICY "Anyone can view poll options" ON community_poll_options FOR SELECT TO public
  USING (true);

-- 10. community_polls: Fix SELECT (keep public for visibility)
DROP POLICY IF EXISTS "Anyone can view polls" ON community_polls;
CREATE POLICY "Anyone can view polls" ON community_polls FOR SELECT TO public
  USING (true);
;
