-- =============================================================================
-- RLS Staging Verification Script
-- =============================================================================
-- Run these queries against the staging Supabase project after applying
-- the 20260329 migration batch (150000, 160000, 170000).
--
-- Usage:
--   1. Connect to staging DB via psql or Supabase SQL Editor
--   2. Run each section in order
--   3. All sections should return PASS results
--
-- Sections:
--   A. FORCE RLS verification
--   B. is_admin() consistency check
--   C. (select auth.uid()) optimization audit
--   D. profiles UPDATE policy guard test (via RPC)
--   E. get_poll_results RPC validation
--   F. admin_users ↔ profiles.role sync trigger test
--   G. Poll vote count sync trigger test
-- =============================================================================


-- =====================================================================
-- A. FORCE ROW LEVEL SECURITY verification
-- =====================================================================
-- Expectation: 0 rows (all tables should have FORCE RLS)

SELECT
  schemaname,
  tablename,
  'MISSING FORCE RLS' AS issue
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename NOT LIKE 'pg_%'
  AND tablename NOT LIKE '_prisma_%'
  AND NOT EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = pg_tables.tablename
      AND c.relforcerowsecurity = true
  )
ORDER BY tablename;

-- Expected: empty result set = PASS


-- =====================================================================
-- B. is_admin() consistency — no remaining admin_users subqueries
-- =====================================================================
-- Checks all policy definitions for direct admin_users references.
-- admin_sessions is whitelisted (FK ownership check).

SELECT
  schemaname,
  tablename,
  policyname,
  'USES admin_users DIRECTLY' AS issue
FROM pg_policies
WHERE schemaname = 'public'
  AND (qual ILIKE '%admin_users%' OR with_check ILIKE '%admin_users%')
  AND tablename NOT IN ('admin_users', 'admin_sessions')
ORDER BY tablename, policyname;

-- Expected: empty result set = PASS
-- If rows appear, those policies still bypass is_admin()


-- =====================================================================
-- C. (select auth.uid()) optimization audit
-- =====================================================================
-- Finds policies using bare auth.uid() (not wrapped in select).
-- Pattern: "auth.uid()" not preceded by "select " within parens.

SELECT
  schemaname,
  tablename,
  policyname,
  'BARE auth.uid() — missing (select ...) wrapper' AS issue
FROM pg_policies
WHERE schemaname = 'public'
  AND (
    qual ~ 'auth\.uid\(\)' AND qual NOT ILIKE '%select auth.uid()%'
    OR
    with_check ~ 'auth\.uid\(\)' AND with_check NOT ILIKE '%select auth.uid()%'
  )
ORDER BY tablename, policyname;

-- Expected: empty result set = PASS
-- Note: some legacy policies may still appear — evaluate on a case-by-case basis


-- =====================================================================
-- D. profiles UPDATE policy guard test
-- =====================================================================
-- Must be run as an AUTHENTICATED non-admin user.
-- Calls the verification RPC created in the migration.

SELECT verify_rls_profiles_update_guards();

-- Expected output:
-- {
--   "user_id": "<uuid>",
--   "user_role": "user",
--   "tests": [
--     {"test": "block_role_escalation",      "passed": true},
--     {"test": "block_premium_escalation",    "passed": true},
--     {"test": "block_subscription_change",   "passed": true},
--     {"test": "block_is_active_change",      "passed": true}
--   ],
--   "all_passed": true
-- }


-- =====================================================================
-- E. get_poll_results RPC validation
-- =====================================================================
-- Prerequisite: need a poll_id that exists in staging.
-- Replace '<poll_id>' with an actual poll UUID.

-- E1. Normal call — should return poll options with vote counts
SELECT * FROM get_poll_results('<poll_id>'::uuid);

-- E2. Non-existent poll — should raise P0002 error
SELECT * FROM get_poll_results('00000000-0000-0000-0000-000000000000'::uuid);
-- Expected: ERROR with "Poll not found"

-- E3. Verify authenticated guard (run as anon if possible)
-- SET role TO anon;
-- SELECT * FROM get_poll_results('<poll_id>'::uuid);
-- Expected: ERROR with "Authentication required" or permission denied
-- RESET role;


-- =====================================================================
-- F. admin_users ↔ profiles.role sync trigger test
-- =====================================================================
-- Run as service_role (triggers fire on any role, but admin_users
-- INSERT policy has WITH CHECK(false) for authenticated — only
-- service_role can insert).

-- F1. Create test user profile (skip if test user already exists)
-- INSERT INTO profiles (id, role, is_deleted, is_active)
-- VALUES ('<test_user_id>', 'user', false, true);

-- F2. Insert into admin_users → profiles.role should become 'admin'
-- INSERT INTO admin_users (user_id) VALUES ('<test_user_id>');
-- SELECT id, role FROM profiles WHERE id = '<test_user_id>';
-- Expected: role = 'admin'

-- F3. Delete from admin_users → profiles.role should revert to 'user'
-- DELETE FROM admin_users WHERE user_id = '<test_user_id>';
-- SELECT id, role FROM profiles WHERE id = '<test_user_id>';
-- Expected: role = 'user'

-- F4. Reverse: update profiles.role → admin_users should auto-create
-- UPDATE profiles SET role = 'admin' WHERE id = '<test_user_id>';
-- SELECT * FROM admin_users WHERE user_id = '<test_user_id>';
-- Expected: row exists

-- F5. Reverse: demote via profiles → admin_users row should be removed
-- UPDATE profiles SET role = 'user' WHERE id = '<test_user_id>';
-- SELECT * FROM admin_users WHERE user_id = '<test_user_id>';
-- Expected: no rows

-- F6. Cleanup
-- DELETE FROM profiles WHERE id = '<test_user_id>';


-- =====================================================================
-- G. Poll vote count sync trigger test
-- =====================================================================
-- Verifies increment/decrement behavior.

-- G1. Check initial state
-- SELECT id, vote_count FROM community_poll_options WHERE poll_id = '<poll_id>';
-- SELECT total_votes FROM community_polls WHERE id = '<poll_id>';

-- G2. Insert a vote (as authenticated user)
-- INSERT INTO community_poll_votes (poll_id, option_id, user_id)
-- VALUES ('<poll_id>', '<option_id>', (SELECT auth.uid()));

-- G3. Check incremented counts
-- SELECT id, vote_count FROM community_poll_options WHERE id = '<option_id>';
-- Expected: vote_count = previous + 1
-- SELECT total_votes FROM community_polls WHERE id = '<poll_id>';
-- Expected: total_votes = previous + 1

-- G4. Delete the vote
-- DELETE FROM community_poll_votes
-- WHERE poll_id = '<poll_id>' AND option_id = '<option_id>' AND user_id = (SELECT auth.uid());

-- G5. Check decremented counts
-- SELECT id, vote_count FROM community_poll_options WHERE id = '<option_id>';
-- Expected: vote_count = back to original
-- SELECT total_votes FROM community_polls WHERE id = '<poll_id>';
-- Expected: total_votes = back to original


-- =====================================================================
-- H. request_account_deletion RPC — cascade verification
-- =====================================================================
-- Run as service_role to create test data, then as authenticated test
-- user to invoke the RPC. Verifies all related rows (including
-- community_blocks.blocked_user_id) are cleaned up.
--
-- Replace '<test_user_id>' with a dedicated disposable test user UUID.

-- H1. Setup: create test user and related data (run as service_role)
-- INSERT INTO auth.users (id, email, encrypted_password, aud, role)
-- VALUES ('<test_user_id>', 'deletion-test@example.com', crypt('Test1234!', gen_salt('bf')), 'authenticated', 'authenticated');
-- INSERT INTO profiles (id, role, is_deleted, is_active)
-- VALUES ('<test_user_id>', 'user', false, true);

-- H2. Create a block where test user IS the blocked party
-- INSERT INTO community_blocks (user_id, blocked_user_id)
-- VALUES ('<other_user_id>', '<test_user_id>');

-- H3. Create a block where test user IS the blocker
-- INSERT INTO community_blocks (user_id, blocked_user_id)
-- VALUES ('<test_user_id>', '<other_user_id>');

-- H4. Invoke the RPC as the test user
-- SET LOCAL role TO authenticated;
-- SET LOCAL request.jwt.claims TO '{"sub": "<test_user_id>", "role": "authenticated"}';
-- SELECT request_account_deletion('<test_user_id>'::uuid);
-- RESET role;

-- H5. Verify all data is deleted
-- SELECT count(*) AS remaining_blocks FROM community_blocks
-- WHERE user_id = '<test_user_id>' OR blocked_user_id = '<test_user_id>';
-- Expected: 0

-- SELECT count(*) AS remaining_profile FROM profiles
-- WHERE id = '<test_user_id>';
-- Expected: 0

-- SELECT count(*) AS remaining_auth FROM auth.users
-- WHERE id = '<test_user_id>';
-- Expected: 0

-- H6. Verify other user's unrelated data is untouched
-- SELECT count(*) AS other_blocks FROM community_blocks
-- WHERE user_id = '<other_user_id>' AND blocked_user_id != '<test_user_id>';
-- Expected: unchanged from before H4

-- H7. Cleanup (if test user was not fully deleted)
-- DELETE FROM community_blocks WHERE user_id = '<test_user_id>' OR blocked_user_id = '<test_user_id>';
-- DELETE FROM profiles WHERE id = '<test_user_id>';
-- DELETE FROM auth.users WHERE id = '<test_user_id>';


-- =====================================================================
-- Summary
-- =====================================================================
-- Section A: 0 rows = all tables have FORCE RLS
-- Section B: 0 rows = no direct admin_users subqueries in policies
-- Section C: 0 rows = all auth.uid() calls optimized
-- Section D: all_passed = true
-- Section E: returns poll options correctly, errors on bad input
-- Section F: bidirectional sync works
-- Section G: increment/decrement counts correct
-- Section H: account deletion cascades correctly (incl. blocked_user_id)
