
-- ============================================================
-- Migration: Drop duplicate permissive policies
-- Fixes: multiple_permissive_policies warnings (18 tables)
-- Strategy: Keep authenticated-role policies, drop redundant public-role ones
-- ============================================================

-- 1. birds: Drop public admin SELECT (already covered by authenticated SELECT with admin OR)
DROP POLICY IF EXISTS "birds_admin_select" ON birds;

-- 2. breeding_pairs: Same pattern as birds
DROP POLICY IF EXISTS "breeding_pairs_admin_select" ON breeding_pairs;

-- 3. security_events: Drop public SELECT (authenticated SELECT already includes own OR admin)
DROP POLICY IF EXISTS "security_events_select" ON security_events;

-- 4. user_sessions: Drop public ALL + public admin SELECT
--    (individual authenticated CRUD policies already cover everything including admin SELECT)
DROP POLICY IF EXISTS "user_sessions_own" ON user_sessions;
DROP POLICY IF EXISTS "user_sessions_admin_select" ON user_sessions;

-- 5. user_subscriptions: Drop public SELECT (authenticated SELECT already includes own OR admin)
DROP POLICY IF EXISTS "user_subscriptions_select" ON user_subscriptions;

-- 6. system_settings: Drop public ALL + public SELECT
--    (individual authenticated CRUD policies already cover admin INSERT/UPDATE/DELETE + user/admin SELECT)
DROP POLICY IF EXISTS "system_settings_modify" ON system_settings;
DROP POLICY IF EXISTS "system_settings_select" ON system_settings;
;
