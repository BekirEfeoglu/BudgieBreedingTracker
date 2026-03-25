-- ============================================================================
-- Migration: Verify and harden admin_users RLS + add admin moderation policy
-- Date: 2026-03-25
-- ============================================================================

-- 1. Ensure RLS is enabled on admin_users (idempotent)
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- 2. admin_users: SELECT policy already exists (admin_users_select_own).
--    INSERT/UPDATE/DELETE are implicitly denied by RLS when no permissive
--    policy exists. Add explicit restrictive-style policies for clarity
--    and defense-in-depth (prevent self-elevation).

-- INSERT: Only service_role can insert admin records (no self-registration)
DROP POLICY IF EXISTS "admin_users_insert_service_only" ON admin_users;
CREATE POLICY "admin_users_insert_service_only"
  ON admin_users FOR INSERT
  TO authenticated
  WITH CHECK (false);

-- UPDATE: Only service_role can update admin records (no self-elevation)
DROP POLICY IF EXISTS "admin_users_update_service_only" ON admin_users;
CREATE POLICY "admin_users_update_service_only"
  ON admin_users FOR UPDATE
  TO authenticated
  USING (false)
  WITH CHECK (false);

-- DELETE: Only service_role can delete admin records
DROP POLICY IF EXISTS "admin_users_delete_service_only" ON admin_users;
CREATE POLICY "admin_users_delete_service_only"
  ON admin_users FOR DELETE
  TO authenticated
  USING (false);

-- 3. community_posts: Allow admin users to update needs_review column
--    Admins can update any post (for moderation: needs_review, visibility, etc.)
DROP POLICY IF EXISTS "Admins can update posts for moderation" ON community_posts;
CREATE POLICY "Admins can update posts for moderation"
  ON community_posts FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = ( SELECT auth.uid() )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = ( SELECT auth.uid() )
    )
  );
