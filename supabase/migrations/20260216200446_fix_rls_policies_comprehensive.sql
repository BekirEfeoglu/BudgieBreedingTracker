
-- ============================================================
-- COMPREHENSIVE RLS POLICY FIX
-- Fixes missing policies for admin operations and user actions
-- ============================================================

-- Helper: reusable admin check expression
-- (auth.uid() IN (SELECT user_id FROM admin_users))

-- ============================================================
-- 1. admin_logs: Add DELETE policy for admins (clear audit logs)
-- ============================================================
CREATE POLICY "admin_logs_delete"
  ON public.admin_logs
  FOR DELETE
  TO authenticated
  USING (
    (SELECT auth.uid()) IN (SELECT user_id FROM admin_users)
  );

-- ============================================================
-- 2. security_events: Add UPDATE + DELETE policies for admins
--    (dismiss/resolve security events)
-- ============================================================
CREATE POLICY "Admins can update security events"
  ON public.security_events
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT auth.uid()) IN (SELECT user_id FROM admin_users)
  )
  WITH CHECK (
    (SELECT auth.uid()) IN (SELECT user_id FROM admin_users)
  );

CREATE POLICY "Admins can delete security events"
  ON public.security_events
  FOR DELETE
  TO authenticated
  USING (
    (SELECT auth.uid()) IN (SELECT user_id FROM admin_users)
  );

-- ============================================================
-- 3. user_subscriptions: Add INSERT + UPDATE policies for admins
--    (grant/revoke premium subscriptions)
-- ============================================================
CREATE POLICY "Admins can insert subscriptions"
  ON public.user_subscriptions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) IN (SELECT user_id FROM admin_users)
  );

CREATE POLICY "Admins can update subscriptions"
  ON public.user_subscriptions
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT auth.uid()) IN (SELECT user_id FROM admin_users)
  )
  WITH CHECK (
    (SELECT auth.uid()) IN (SELECT user_id FROM admin_users)
  );

-- ============================================================
-- 4. profiles: Fix UPDATE WITH CHECK to allow admin to set is_active
--    Current WITH CHECK blocks admins from changing is_active because
--    the non-admin branch only allows unchanged is_premium/role/status.
--    We need to drop the existing policy and recreate it properly.
-- ============================================================
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    ((SELECT auth.uid()) = id)
    OR
    ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users))
  )
  WITH CHECK (
    -- Admins can update any field on any profile
    ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users))
    OR
    -- Regular users can only update their own profile,
    -- but cannot change sensitive fields (is_premium, role, subscription_status, is_active)
    (
      ((SELECT auth.uid()) = id)
      AND (is_premium = (SELECT p.is_premium FROM profiles p WHERE p.id = (SELECT auth.uid())))
      AND (NOT (role IS DISTINCT FROM (SELECT p.role FROM profiles p WHERE p.id = (SELECT auth.uid()))))
      AND (subscription_status = (SELECT p.subscription_status FROM profiles p WHERE p.id = (SELECT auth.uid())))
      AND (is_active = (SELECT p.is_active FROM profiles p WHERE p.id = (SELECT auth.uid())))
    )
  );

-- ============================================================
-- 5. community_poll_options: Add INSERT for post owners
-- ============================================================
CREATE POLICY "Post owners can insert poll options"
  ON public.community_poll_options
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM community_polls cp
      JOIN community_posts cpost ON cpost.id = cp.post_id
      WHERE cp.id = community_poll_options.poll_id
        AND cpost.user_id = (SELECT auth.uid())
    )
  );

-- ============================================================
-- 6. community_polls: Add DELETE for post owners
-- ============================================================
CREATE POLICY "Post owners can delete polls"
  ON public.community_polls
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM community_posts
      WHERE community_posts.id = community_polls.post_id
        AND community_posts.user_id = (SELECT auth.uid())
    )
  );

-- ============================================================
-- 7. notification_history: Add DELETE for own records
-- ============================================================
CREATE POLICY "Users can delete own notification history"
  ON public.notification_history
  FOR DELETE
  TO authenticated
  USING (
    (SELECT auth.uid()) = user_id
  );

-- ============================================================
-- 8. admin_logs: Add UPDATE policy for admins (in case needed)
-- ============================================================
CREATE POLICY "admin_logs_update"
  ON public.admin_logs
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT auth.uid()) IN (SELECT user_id FROM admin_users)
  )
  WITH CHECK (
    (SELECT auth.uid()) IN (SELECT user_id FROM admin_users)
  );
;
