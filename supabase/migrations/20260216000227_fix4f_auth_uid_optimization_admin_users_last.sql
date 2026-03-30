
-- Fix the last remaining policy using direct auth.uid()
DROP POLICY IF EXISTS "Admin users can read own record" ON admin_users;
CREATE POLICY "Admin users can read own record" ON admin_users FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);
;
