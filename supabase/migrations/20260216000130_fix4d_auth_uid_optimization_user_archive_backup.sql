
-- Fix 4d: Replace auth.uid() with (select auth.uid()) for user, archive, backup tables

-- ========== USER_PREFERENCES ==========
DROP POLICY IF EXISTS "Users can manage own preferences" ON user_preferences;
CREATE POLICY "Users can manage own preferences" ON user_preferences FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== USER_SESSIONS ==========
DROP POLICY IF EXISTS "Users can manage own sessions" ON user_sessions;
DROP POLICY IF EXISTS "Users can view own sessions" ON user_sessions;
CREATE POLICY "Users can manage own sessions" ON user_sessions FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== USER_SUBSCRIPTIONS ==========
DROP POLICY IF EXISTS "Users can view own subscriptions" ON user_subscriptions;
CREATE POLICY "Users can view own subscriptions" ON user_subscriptions FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== FEEDBACK ==========
DROP POLICY IF EXISTS "Users can manage own feedback" ON feedback;
DROP POLICY IF EXISTS "Admins can view all feedback" ON feedback;
CREATE POLICY "Users can manage own feedback" ON feedback FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Admins can view all feedback" ON feedback FOR SELECT TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));

-- ========== ARCHIVE TABLES ==========
DROP POLICY IF EXISTS "Users can manage own archived birds" ON archived_birds;
CREATE POLICY "Users can manage own archived birds" ON archived_birds FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can manage own archived pairs" ON archived_breeding_pairs;
CREATE POLICY "Users can manage own archived pairs" ON archived_breeding_pairs FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can manage own archived chicks" ON archived_chicks;
CREATE POLICY "Users can manage own archived chicks" ON archived_chicks FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can manage own archived clutches" ON archived_clutches;
CREATE POLICY "Users can manage own archived clutches" ON archived_clutches FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can manage own archived eggs" ON archived_eggs;
CREATE POLICY "Users can manage own archived eggs" ON archived_eggs FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can manage own archive jobs" ON archive_jobs;
CREATE POLICY "Users can manage own archive jobs" ON archive_jobs FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can manage own archive settings" ON archive_settings;
CREATE POLICY "Users can manage own archive settings" ON archive_settings FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== BACKUP TABLES ==========
DROP POLICY IF EXISTS "Users can manage own backups" ON backup_history;
CREATE POLICY "Users can manage own backups" ON backup_history FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can manage own backup jobs" ON backup_jobs;
CREATE POLICY "Users can manage own backup jobs" ON backup_jobs FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can manage own backup settings" ON backup_settings;
CREATE POLICY "Users can manage own backup settings" ON backup_settings FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can manage own config backups" ON config_backups;
CREATE POLICY "Users can manage own config backups" ON config_backups FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== PRIVACY ==========
DROP POLICY IF EXISTS "Users can manage own privacy" ON privacy_settings;
CREATE POLICY "Users can manage own privacy" ON privacy_settings FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view own privacy logs" ON privacy_audit_logs;
DROP POLICY IF EXISTS "Admins can view all privacy logs" ON privacy_audit_logs;
DROP POLICY IF EXISTS "System can insert logs" ON privacy_audit_logs;

CREATE POLICY "Users can view own privacy logs" ON privacy_audit_logs FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Admins can view all privacy logs" ON privacy_audit_logs FOR SELECT TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));
CREATE POLICY "Users can insert own privacy logs" ON privacy_audit_logs FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
;
