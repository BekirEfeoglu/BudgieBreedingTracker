
-- Add admin read access policies for the admin panel.
-- These allow admin users to view all records (not just their own).
-- The admin_users table now has a non-recursive policy, so these subqueries work correctly.

-- Profiles: admins can view all user profiles
CREATE POLICY "Admins can view all profiles"
  ON profiles
  FOR SELECT
  USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- User sessions: admins can view all sessions (for active user counts)
CREATE POLICY "Admins can view all sessions"
  ON user_sessions
  FOR SELECT
  USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- User subscriptions: admins can view all subscriptions
CREATE POLICY "Admins can view all subscriptions"
  ON user_subscriptions
  FOR SELECT
  USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- Birds: admins can view all birds (for stats and user detail)
CREATE POLICY "Admins can view all birds"
  ON birds
  FOR SELECT
  USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- Breeding pairs: admins can view all breeding pairs (for stats)
CREATE POLICY "Admins can view all breeding pairs"
  ON breeding_pairs
  FOR SELECT
  USING (auth.uid() IN (SELECT user_id FROM admin_users));
;
