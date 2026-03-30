
-- Fix 3: Fix overly permissive INSERT policies on error_logs and security_events
-- Problem: "WITH CHECK (true)" allows ANY authenticated user to insert anything

-- 1. Fix error_logs: Replace "System can insert errors" (WITH CHECK true) 
--    with user-scoped insert (auth.uid() = user_id)
DROP POLICY IF EXISTS "System can insert errors" ON error_logs;
CREATE POLICY "Users can insert own errors" ON error_logs
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

-- 2. Fix security_events: Replace "System can insert events" (WITH CHECK true)
--    with user-scoped insert (auth.uid() = user_id)
DROP POLICY IF EXISTS "System can insert events" ON security_events;
CREATE POLICY "Users can insert own security events" ON security_events
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
;
