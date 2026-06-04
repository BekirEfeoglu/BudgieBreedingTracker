-- =============================================================================
-- Fix app-owned Supabase db lint warnings
-- =============================================================================
-- Linked lint still flagged two application-owned functions after the
-- community_blocks and cleanup drift repairs:
--   1. private.admin_reset_all_user_data initialized a text[] with '{}'.
--   2. public.sync_premium_status is intentionally fail-closed and therefore
--      did not reference its compatibility parameters before raising.
--
-- This migration preserves behavior and only makes the function bodies clearer
-- to the database linter.
-- =============================================================================

CREATE OR REPLACE FUNCTION private.admin_reset_all_user_data()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  protected_tables text[] := ARRAY[
    'admin_users', 'admin_logs', 'admin_rate_limits', 'admin_sessions',
    'system_settings', 'system_status', 'system_metrics', 'system_alerts',
    'subscription_plans', 'profiles', 'error_logs', 'privacy_audit_logs',
    'security_events', 'backup_history', 'backup_settings', 'config_backups'
  ];
  tbl_name text;
  total_deleted bigint := 0;
  tbl_count bigint;
  reset_tables text[] := ARRAY[]::text[];
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.admin_users
    WHERE user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Admin permission denied';
  END IF;

  FOR tbl_name IN
    SELECT t.table_name::text
    FROM information_schema.tables t
    WHERE t.table_schema = 'public'
      AND t.table_type = 'BASE TABLE'
      AND t.table_name != ALL(protected_tables)
    ORDER BY t.table_name
  LOOP
    EXECUTE format('SELECT COUNT(*) FROM public.%I', tbl_name) INTO tbl_count;

    IF tbl_count > 0 THEN
      total_deleted := total_deleted + tbl_count;
      reset_tables := array_append(reset_tables, tbl_name);
    END IF;

    EXECUTE format('TRUNCATE TABLE public.%I CASCADE', tbl_name);
  END LOOP;

  INSERT INTO public.admin_logs (admin_user_id, target_user_id, action, details)
  VALUES (
    auth.uid(),
    auth.uid(),
    'all_data_reset',
    jsonb_build_object(
      'message',
      format(
        'All user data reset. %s rows removed from %s tables.',
        total_deleted,
        array_length(reset_tables, 1)
      )
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'total_rows_deleted', total_deleted,
    'tables_reset', to_jsonb(reset_tables)
  );
END;
$function$;

REVOKE ALL ON FUNCTION private.admin_reset_all_user_data()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.admin_reset_all_user_data()
  TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.sync_premium_status(
  p_is_premium boolean,
  p_subscription_status text DEFAULT 'free',
  p_premium_expires_at timestamptz DEFAULT NULL,
  p_plan text DEFAULT 'premium',
  p_current_period_end timestamptz DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  PERFORM p_is_premium, p_subscription_status, p_premium_expires_at, p_plan, p_current_period_end;

  RAISE EXCEPTION USING
    ERRCODE = '42501',
    MESSAGE = 'premium_sync_requires_server_verification',
    DETAIL = 'Use the sync-premium-status Edge Function; it verifies RevenueCat server-side before updating premium fields.';
END;
$$;

REVOKE ALL ON FUNCTION public.sync_premium_status(
  boolean,
  text,
  timestamptz,
  text,
  timestamptz
) FROM PUBLIC, anon, authenticated;

COMMENT ON FUNCTION public.sync_premium_status(
  boolean,
  text,
  timestamptz,
  text,
  timestamptz
) IS
  'Fail-closed compatibility stub. Client-side premium assertions are forbidden; '
  'sync premium through the sync-premium-status Edge Function, which validates '
  'RevenueCat with a server-only key.';
