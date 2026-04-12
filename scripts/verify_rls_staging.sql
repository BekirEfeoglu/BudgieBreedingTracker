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
-- I. is_conversation_member search_path verification
-- =====================================================================
-- After Phase 3 migration, verify that is_conversation_member has
-- SET search_path TO '' (not 'public') for SECURITY DEFINER safety.

SELECT
  proname AS function_name,
  proconfig AS config,
  CASE
    WHEN proconfig::text ILIKE '%search_path=%' AND proconfig::text NOT ILIKE '%search_path=public%'
    THEN 'PASS: search_path hardened'
    WHEN proconfig::text ILIKE '%search_path=public%'
    THEN 'FAIL: still using search_path=public'
    ELSE 'FAIL: no search_path set'
  END AS status
FROM pg_proc
WHERE proname = 'is_conversation_member'
  AND pronamespace = 'public'::regnamespace;

-- Expected: status = 'PASS: search_path hardened'


-- =====================================================================
-- J. pg_trgm extension schema verification
-- =====================================================================
-- Verify pg_trgm is in extensions schema and operator class works.

SELECT
  extname,
  nspname AS schema,
  CASE
    WHEN nspname = 'extensions' THEN 'PASS: in extensions schema'
    WHEN nspname = 'public' THEN 'WARN: still in public schema'
    ELSE 'INFO: in ' || nspname
  END AS status
FROM pg_extension e
JOIN pg_namespace n ON n.oid = e.extnamespace
WHERE extname = 'pg_trgm';

-- Expected: status = 'PASS: in extensions schema'

-- Verify gin_trgm_ops indexes still work
SELECT
  indexname,
  tablename,
  pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE indexdef ILIKE '%gin_trgm_ops%'
  AND schemaname = 'public'
ORDER BY tablename;

-- Expected: 4 indexes (community_posts x2, marketplace_listings x2)


-- =====================================================================
-- K. SECURITY DEFINER functions search_path audit
-- =====================================================================
-- All SECURITY DEFINER functions should have explicit search_path.
-- Functions without search_path are a SQL injection vector.

SELECT
  proname AS function_name,
  CASE
    WHEN proconfig IS NULL THEN 'FAIL: no config (no search_path)'
    WHEN NOT (proconfig::text ILIKE '%search_path%') THEN 'FAIL: no search_path'
    ELSE 'PASS: search_path set'
  END AS status,
  proconfig AS config
FROM pg_proc
WHERE prosecdef = true
  AND pronamespace = 'public'::regnamespace
ORDER BY proname;

-- Expected: all rows show 'PASS: search_path set'


-- =====================================================================
-- L. Free tier limit RLS policies verification
-- =====================================================================
-- Verifies the three free tier INSERT policies exist and that
-- is_premium_or_privileged() is deployed with correct search_path.

-- L1. Verify is_premium_or_privileged function exists and is hardened
SELECT
  proname AS function_name,
  prosecdef AS security_definer,
  CASE
    WHEN proconfig::text ILIKE '%search_path=%' AND proconfig::text NOT ILIKE '%search_path=public%'
    THEN 'PASS: search_path hardened'
    WHEN proconfig::text ILIKE '%search_path=public%'
    THEN 'FAIL: still using search_path=public'
    ELSE 'FAIL: no search_path set'
  END AS status
FROM pg_proc
WHERE proname = 'is_premium_or_privileged'
  AND pronamespace = 'public'::regnamespace;

-- Expected: 1 row, security_definer = true, status = 'PASS: search_path hardened'

-- L2. Verify all three free tier limit policies exist
SELECT
  tablename,
  policyname,
  cmd AS command,
  CASE WHEN with_check ILIKE '%is_premium_or_privileged%'
    THEN 'PASS: uses premium bypass'
    ELSE 'FAIL: missing premium bypass'
  END AS premium_check
FROM pg_policies
WHERE schemaname = 'public'
  AND policyname IN (
    'free_tier_bird_limit',
    'free_tier_breeding_pair_limit',
    'free_tier_incubation_limit'
  )
ORDER BY tablename;

-- Expected: 3 rows, all with premium_check = 'PASS'
-- Missing rows indicate the policy was not applied to that table.

-- L3. Functional test — count-based limit check
-- Run as authenticated non-premium user with < 15 birds.
-- This should succeed:
-- INSERT INTO birds (id, user_id, name, gender, is_deleted)
-- VALUES (gen_random_uuid(), auth.uid(), 'RLS Test Bird', 'male', false);
-- Then clean up:
-- DELETE FROM birds WHERE name = 'RLS Test Bird' AND user_id = auth.uid();

-- L4. Functional test — limit exceeded (requires 15+ birds seeded)
-- Expects: new_row_violates_row_level_security error
-- INSERT INTO birds (id, user_id, name, gender, is_deleted)
-- VALUES (gen_random_uuid(), auth.uid(), 'Over Limit Bird', 'male', false);

-- L5. Premium bypass test — run as premium user
-- Premium user should always succeed regardless of count.
-- Verify with: SELECT is_premium_or_privileged(auth.uid());
-- Expected: true


-- =====================================================================
-- M. sync_premium_status RPC verification
-- =====================================================================
-- Verifies the sync_premium_status RPC is deployed, has correct
-- security settings, and functions correctly.

-- M1. Verify function exists with correct security settings
SELECT
  proname AS function_name,
  prosecdef AS security_definer,
  pronargs AS param_count,
  CASE
    WHEN proconfig::text ILIKE '%search_path=%' AND proconfig::text NOT ILIKE '%search_path=public%'
    THEN 'PASS: search_path hardened'
    WHEN proconfig::text ILIKE '%search_path=public%'
    THEN 'FAIL: still using search_path=public'
    ELSE 'FAIL: no search_path set'
  END AS search_path_status
FROM pg_proc
WHERE proname = 'sync_premium_status'
  AND pronamespace = 'public'::regnamespace;

-- Expected: 1 row, security_definer = true, param_count = 5,
--           search_path_status = 'PASS: search_path hardened'

-- M2. Verify authenticated role has execute permission
SELECT
  grantee,
  privilege_type
FROM information_schema.routine_privileges
WHERE routine_name = 'sync_premium_status'
  AND routine_schema = 'public'
  AND grantee = 'authenticated';

-- Expected: 1 row with privilege_type = 'EXECUTE'

-- M3. Functional test — activate premium (run as authenticated user)
-- SELECT sync_premium_status(
--   true,                         -- p_is_premium
--   'premium',                    -- p_subscription_status
--   now() + interval '6 months',  -- p_premium_expires_at
--   'premium',                    -- p_plan
--   now() + interval '6 months'   -- p_current_period_end
-- );
-- Expected: {"success": true, "user_id": "<uuid>", "is_premium": true}
-- Verify: SELECT is_premium, subscription_status, premium_expires_at
--         FROM profiles WHERE id = auth.uid();

-- M4. Functional test — deactivate premium (run as same user)
-- SELECT sync_premium_status(
--   false,                        -- p_is_premium
--   'free',                       -- p_subscription_status
--   NULL,                         -- p_premium_expires_at
--   'premium',                    -- p_plan
--   NULL                          -- p_current_period_end
-- );
-- Expected: {"success": true, "user_id": "<uuid>", "is_premium": false}
-- Verify: SELECT status FROM user_subscriptions WHERE user_id = auth.uid();
-- Expected: status = 'cancelled'

-- M5. Verify unauthenticated call fails
-- SET role TO anon;
-- SELECT sync_premium_status(true, 'premium');
-- Expected: ERROR 'Authentication required'
-- RESET role;


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
-- Section I: is_conversation_member has hardened search_path
-- Section J: pg_trgm in extensions schema, gin indexes work
-- Section K: all SECURITY DEFINER functions have search_path
-- Section L: free tier limit RLS policies deployed with premium bypass
-- Section M: sync_premium_status RPC deployed with correct security
