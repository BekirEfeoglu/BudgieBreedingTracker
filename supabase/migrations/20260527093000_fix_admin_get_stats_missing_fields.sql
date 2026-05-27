-- Restore the contract between `private.admin_get_stats()` and the
-- Dart-side `AdminStats.fromJson` model.
--
-- Background
-- ----------
-- The original RPC (migration 20260216201209) returned 5 keys
-- (`total_users`, `total_birds`, `active_breedings`, `active_today`,
-- `new_users_today`). The Dart model `AdminStats` expects 9 keys —
-- the other 4 (`premium_count`, `free_count`, `pending_sync_count`,
-- `error_sync_count`) fell through to `@Default(0)`, so the admin
-- dashboard silently showed "0" for premium and sync counters even
-- when the real counts were non-zero (e.g. 5 premium users on
-- production at the time of this migration).
--
-- Two additional defects in the original body:
--   * `total_birds` counted soft-deleted rows (`is_deleted = true`).
--   * `active_breedings` counted ALL breeding_pairs regardless of
--     `status` — so a "completed" pair was being labeled as "active"
--     on the dashboard.
--
-- Fix
-- ---
-- Recreate the function with the full 9-key payload, soft-delete
-- filters where appropriate, and an explicit `status = 'active'`
-- guard on `active_breedings`. `active_today` keeps the original
-- "sessions today, fall back to profiles updated today" heuristic
-- so the existing dashboard number remains stable.
--
-- Idempotent: CREATE OR REPLACE.

CREATE OR REPLACE FUNCTION private.admin_get_stats()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  result json;
  v_today timestamp;
  v_sessions_today integer;
  v_total_users integer;
  v_premium_count integer;
BEGIN
  -- Admin enforcement: must exist in admin_users.
  IF NOT EXISTS (
    SELECT 1 FROM admin_users WHERE user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Admin permission denied';
  END IF;

  v_today := date_trunc('day', now() at time zone 'UTC');

  -- Compute these once so the JSON build below stays readable and the
  -- free_count derivation doesn't require a second profiles scan.
  v_sessions_today := (
    SELECT COUNT(DISTINCT user_id) FROM user_sessions WHERE created_at >= v_today
  );
  v_total_users := (SELECT COUNT(*) FROM profiles);
  v_premium_count := (SELECT COUNT(*) FROM profiles WHERE is_premium = true);

  SELECT json_build_object(
    'total_users', v_total_users,
    'active_today', v_sessions_today + CASE
      WHEN v_sessions_today = 0
        THEN (SELECT COUNT(*) FROM profiles WHERE updated_at >= v_today)
      ELSE 0
    END,
    'new_users_today', (
      SELECT COUNT(*) FROM profiles WHERE created_at >= v_today
    ),
    'total_birds', (
      SELECT COUNT(*) FROM birds WHERE is_deleted = false
    ),
    'active_breedings', (
      SELECT COUNT(*) FROM breeding_pairs
      WHERE is_deleted = false AND status = 'active'
    ),
    'premium_count', v_premium_count,
    'free_count', v_total_users - v_premium_count,
    'pending_sync_count', (
      SELECT COUNT(*) FROM sync_metadata WHERE status = 'pending'
    ),
    'error_sync_count', (
      SELECT COUNT(*) FROM sync_metadata WHERE status = 'error'
    )
  ) INTO result;

  RETURN result;
END;
$$;

-- Public wrapper is unchanged (created by 20260501115000); it simply
-- delegates to the private function via SECURITY INVOKER. No changes
-- needed there.
