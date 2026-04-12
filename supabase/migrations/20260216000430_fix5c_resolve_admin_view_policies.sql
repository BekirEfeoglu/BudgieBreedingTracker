
-- Fix 5c: Combine admin+user SELECT policies into single policy
-- Fixes both auth_rls_initplan and multiple_permissive_policies

-- ========== PROFILES ==========
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view profiles" ON profiles FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = id 
    OR (select auth.uid()) IN (SELECT user_id FROM admin_users)
  );

-- ========== BIRDS ==========
DROP POLICY IF EXISTS "Admins can view all birds" ON birds;
DROP POLICY IF EXISTS "Users can view own birds" ON birds;
CREATE POLICY "Users can view birds" ON birds FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id 
    OR (select auth.uid()) IN (SELECT user_id FROM admin_users)
  );

-- ========== BREEDING_PAIRS ==========
DROP POLICY IF EXISTS "Admins can view all breeding pairs" ON breeding_pairs;
DROP POLICY IF EXISTS "Users can view own breeding_pairs" ON breeding_pairs;
CREATE POLICY "Users can view breeding_pairs" ON breeding_pairs FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id 
    OR (select auth.uid()) IN (SELECT user_id FROM admin_users)
  );

-- ========== USER_SESSIONS ==========
-- Has ALL + admin SELECT: split ALL into INSERT/UPDATE/DELETE, combine SELECTs
DROP POLICY IF EXISTS "Admins can view all sessions" ON user_sessions;
DROP POLICY IF EXISTS "Users can manage own sessions" ON user_sessions;
CREATE POLICY "Users can view sessions" ON user_sessions FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id 
    OR (select auth.uid()) IN (SELECT user_id FROM admin_users)
  );
CREATE POLICY "Users can insert own sessions" ON user_sessions FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own sessions" ON user_sessions FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own sessions" ON user_sessions FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== USER_SUBSCRIPTIONS ==========
DROP POLICY IF EXISTS "Admins can view all subscriptions" ON user_subscriptions;
DROP POLICY IF EXISTS "Users can view own subscriptions" ON user_subscriptions;
CREATE POLICY "Users can view subscriptions" ON user_subscriptions FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id 
    OR (select auth.uid()) IN (SELECT user_id FROM admin_users)
  );
;
