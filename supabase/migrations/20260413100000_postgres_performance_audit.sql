-- =============================================================================
-- Migration: Postgres Performance Audit
-- Date: 2026-04-13
-- Description: Implements all recommendations from comprehensive Postgres audit
--   1. Missing indexes on searchable/filterable columns
--   2. Missing updated_at column + trigger on archive_jobs
--   3. Cleanup functions for stale data (notification_rate_limits, backup_history)
--   4. Autovacuum tuning for high-churn tables
--   5. JSONB index optimization (jsonb_path_ops for smaller, faster indexes)
--   6. is_admin() JWT custom claim hook for RLS performance
-- =============================================================================

-- =============================================================================
-- 1. MISSING INDEXES
-- =============================================================================

-- profiles: searchable fields (community search, admin lookup)
CREATE INDEX IF NOT EXISTS idx_profiles_display_name
  ON profiles (display_name)
  WHERE display_name IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_full_name
  ON profiles (full_name)
  WHERE full_name IS NOT NULL;

-- birds: user search fields (ring_number, cage_number)
CREATE INDEX IF NOT EXISTS idx_birds_ring_number
  ON birds (user_id, ring_number)
  WHERE is_deleted = false AND ring_number IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_birds_cage_number
  ON birds (user_id, cage_number)
  WHERE is_deleted = false AND cage_number IS NOT NULL;

-- health_records: date-based filtering
CREATE INDEX IF NOT EXISTS idx_health_records_date
  ON health_records (user_id, date DESC)
  WHERE is_deleted = false;

-- notifications: unread notifications listing
CREATE INDEX IF NOT EXISTS idx_notifications_unread
  ON notifications (user_id, created_at DESC)
  WHERE read = false;

-- =============================================================================
-- 2. MISSING UPDATED_AT ON ARCHIVE_JOBS
-- =============================================================================

ALTER TABLE archive_jobs
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

CREATE OR REPLACE TRIGGER update_archive_jobs_updated_at
  BEFORE UPDATE ON archive_jobs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- 3. CLEANUP FUNCTIONS
-- =============================================================================

-- 3a. Clean up expired notification rate limit windows
-- Removes windows older than 24 hours (well past any window_duration_minutes)
CREATE OR REPLACE FUNCTION cleanup_expired_rate_limits()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.notification_rate_limits
  WHERE window_start < now() - interval '24 hours';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

-- 3b. Clean up expired backup history records
-- Removes records past their expires_at date with status = 'completed'
CREATE OR REPLACE FUNCTION cleanup_expired_backups()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.backup_history
  WHERE expires_at IS NOT NULL
    AND expires_at < now()
    AND status = 'completed';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

-- 3c. Combined maintenance function (call via pg_cron or Edge Function)
CREATE OR REPLACE FUNCTION run_scheduled_cleanup()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  rate_limits_cleaned integer;
  backups_cleaned integer;
BEGIN
  SELECT public.cleanup_expired_rate_limits() INTO rate_limits_cleaned;
  SELECT public.cleanup_expired_backups() INTO backups_cleaned;

  RETURN jsonb_build_object(
    'rate_limits_cleaned', rate_limits_cleaned,
    'backups_cleaned', backups_cleaned,
    'executed_at', now()
  );
END;
$$;

-- =============================================================================
-- 4. AUTOVACUUM TUNING FOR HIGH-CHURN TABLES
-- =============================================================================

-- sync_metadata: high write/delete volume during sync operations
ALTER TABLE sync_metadata SET (
  autovacuum_vacuum_scale_factor = 0.05,
  autovacuum_analyze_scale_factor = 0.02
);

-- notification_rate_limits: frequent inserts/deletes
ALTER TABLE notification_rate_limits SET (
  autovacuum_vacuum_scale_factor = 0.05,
  autovacuum_analyze_scale_factor = 0.02
);

-- notifications: high volume, frequent read/update
ALTER TABLE notifications SET (
  autovacuum_vacuum_scale_factor = 0.1,
  autovacuum_analyze_scale_factor = 0.05
);

-- =============================================================================
-- 5. JSONB INDEX OPTIMIZATION (jsonb_path_ops)
-- jsonb_path_ops only supports @> operator but is 2-3x smaller
-- All current JSONB queries use @> containment, so this is safe
-- =============================================================================

-- Drop old default-ops GIN indexes and recreate with path_ops
DROP INDEX IF EXISTS idx_birds_mutations_gin;
CREATE INDEX idx_birds_mutations_gin
  ON birds USING GIN (mutations jsonb_path_ops);

DROP INDEX IF EXISTS idx_birds_genotype_info_gin;
CREATE INDEX idx_birds_genotype_info_gin
  ON birds USING GIN (genotype_info jsonb_path_ops);

DROP INDEX IF EXISTS idx_genetics_history_results_gin;
CREATE INDEX idx_genetics_history_results_gin
  ON genetics_history USING GIN (results jsonb_path_ops);

-- =============================================================================
-- 6. is_admin() OPTIMIZATION VIA JWT CUSTOM CLAIM
-- =============================================================================

-- Custom access token hook function
-- Supabase calls this during token generation to add custom claims
-- This eliminates per-query admin_users/profiles lookups in RLS policies
CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  claims jsonb;
  user_role text;
  user_is_premium boolean;
BEGIN
  claims := event->'claims';

  -- Fetch role and premium status in a single query
  SELECT p.role, p.is_premium
  INTO user_role, user_is_premium
  FROM public.profiles p
  WHERE p.id = (event->>'user_id')::uuid;

  -- Set custom claims
  IF user_role IS NOT NULL THEN
    claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role));
  ELSE
    claims := jsonb_set(claims, '{user_role}', '"authenticated"');
  END IF;

  claims := jsonb_set(claims, '{is_admin}', to_jsonb(
    COALESCE(user_role IN ('admin', 'founder'), false)
  ));

  claims := jsonb_set(claims, '{is_premium}', to_jsonb(
    COALESCE(user_is_premium, false)
  ));

  -- Update event with new claims
  event := jsonb_set(event, '{claims}', claims);

  RETURN event;
END;
$$;

-- Grant execute to supabase_auth_admin (required for auth hooks)
GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO supabase_auth_admin;

-- Revoke from public for security
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook FROM anon;
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook FROM authenticated;

-- Optimized is_admin() that checks JWT claim first, falls back to DB
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  jwt_claim boolean;
BEGIN
  -- Try JWT claim first (no DB lookup needed)
  jwt_claim := coalesce(
    ((current_setting('request.jwt.claims', true)::jsonb)->>'is_admin')::boolean,
    false
  );

  IF jwt_claim THEN
    RETURN true;
  END IF;

  -- Fallback to DB lookup (for tokens issued before hook was enabled)
  RETURN EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'founder')
      AND is_active = TRUE
  );
END;
$$;

-- Optimized is_premium_or_privileged() with JWT claim check
CREATE OR REPLACE FUNCTION public.is_premium_or_privileged(p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  jwt_claims jsonb;
BEGIN
  -- If checking own status, try JWT claim first
  IF p_user_id = (SELECT auth.uid()) THEN
    jwt_claims := current_setting('request.jwt.claims', true)::jsonb;
    IF (jwt_claims->>'is_admin')::boolean = true
       OR (jwt_claims->>'is_premium')::boolean = true THEN
      RETURN true;
    END IF;
  END IF;

  -- Fallback to DB lookup
  RETURN COALESCE(
    (
      SELECT p.is_premium OR p.role IN ('admin', 'founder')
      FROM public.profiles p
      WHERE p.id = p_user_id
    ),
    false
  );
END;
$$;
