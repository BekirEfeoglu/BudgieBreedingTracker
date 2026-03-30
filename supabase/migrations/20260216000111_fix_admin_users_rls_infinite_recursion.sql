
-- Fix infinite recursion in admin_users RLS policy.
-- The old policy referenced admin_users table itself causing infinite recursion.
-- New policy uses direct auth.uid() = user_id check (no self-reference).

-- Drop the recursive policy
DROP POLICY IF EXISTS "Admin users can read admin list" ON admin_users;

-- Create non-recursive policy: each admin can see their own row
CREATE POLICY "Admin users can read own record"
  ON admin_users
  FOR SELECT
  USING (auth.uid() = user_id);
;
