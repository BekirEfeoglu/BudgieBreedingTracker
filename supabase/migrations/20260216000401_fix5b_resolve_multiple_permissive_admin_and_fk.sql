
-- Fix 5b: Resolve multiple permissive policies for admin/system tables + missing FK index

-- ========== ADMIN_USERS: Combine 2 SELECT policies into 1 ==========
DROP POLICY IF EXISTS "Admin users can read admin list" ON admin_users;
DROP POLICY IF EXISTS "Admin users can read own record" ON admin_users;
CREATE POLICY "Admin users can read" ON admin_users FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id 
    OR (select auth.uid()) IN (SELECT user_id FROM admin_users)
  );

-- ========== ERROR_LOGS: Split admin ALL to avoid INSERT overlap ==========
DROP POLICY IF EXISTS "Admins can manage error logs" ON error_logs;
-- Keep: "Users can insert own errors" (INSERT)
CREATE POLICY "Admins can view error logs" ON error_logs FOR SELECT TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));
CREATE POLICY "Admins can update error logs" ON error_logs FOR UPDATE TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));
CREATE POLICY "Admins can delete error logs" ON error_logs FOR DELETE TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));

-- ========== FEEDBACK: Split user ALL to avoid SELECT overlap ==========
DROP POLICY IF EXISTS "Users can manage own feedback" ON feedback;
-- Keep: "Admins can view all feedback" (SELECT)
-- Combine user+admin SELECT into one:
DROP POLICY IF EXISTS "Admins can view all feedback" ON feedback;
CREATE POLICY "Users can view feedback" ON feedback FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id 
    OR (select auth.uid()) IN (SELECT user_id FROM admin_users)
  );
CREATE POLICY "Users can insert own feedback" ON feedback FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own feedback" ON feedback FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own feedback" ON feedback FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== PRIVACY_AUDIT_LOGS: Combine 2 SELECT policies into 1 ==========
DROP POLICY IF EXISTS "Admins can view all privacy logs" ON privacy_audit_logs;
DROP POLICY IF EXISTS "Users can view own privacy logs" ON privacy_audit_logs;
CREATE POLICY "Users can view privacy logs" ON privacy_audit_logs FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id 
    OR (select auth.uid()) IN (SELECT user_id FROM admin_users)
  );

-- ========== SECURITY_EVENTS: Combine 2 SELECT policies into 1 ==========
DROP POLICY IF EXISTS "Admins can view all security events" ON security_events;
DROP POLICY IF EXISTS "Users can view own security events" ON security_events;
CREATE POLICY "Users can view security events" ON security_events FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id 
    OR (select auth.uid()) IN (SELECT user_id FROM admin_users)
  );

-- ========== SYSTEM_SETTINGS: Split admin ALL to avoid SELECT overlap ==========
DROP POLICY IF EXISTS "Admins can manage all settings" ON system_settings;
-- Keep: "Anyone can view public settings" (SELECT, is_public = true)
-- Combine admin+public SELECT:
DROP POLICY IF EXISTS "Anyone can view public settings" ON system_settings;
CREATE POLICY "Users can view settings" ON system_settings FOR SELECT TO authenticated
  USING (
    is_public = true 
    OR (select auth.uid()) IN (SELECT user_id FROM admin_users)
  );
CREATE POLICY "Admins can insert settings" ON system_settings FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) IN (SELECT user_id FROM admin_users));
CREATE POLICY "Admins can update settings" ON system_settings FOR UPDATE TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));
CREATE POLICY "Admins can delete settings" ON system_settings FOR DELETE TO authenticated
  USING ((select auth.uid()) IN (SELECT user_id FROM admin_users));

-- ========== FIX MISSING FK INDEX ==========
-- chicks.chicks_clutch_id_fkey_v2 (unindexed FK on clutch_id)
CREATE INDEX IF NOT EXISTS idx_chicks_clutch_id ON chicks (clutch_id);
;
