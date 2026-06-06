-- =============================================================================
-- Harden admin reset RPC authorization and admin log mutability
-- =============================================================================
-- Client-side founder checks are not authorization. The destructive reset RPCs
-- must enforce founder-only access inside the SECURITY DEFINER implementation.
-- Admin logs must remain append-only from the client-visible API surface.
-- =============================================================================

CREATE OR REPLACE FUNCTION private.admin_reset_table(p_table_name text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  rows_deleted bigint;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.admin_users au
    JOIN public.profiles p ON p.id = au.user_id
    WHERE au.user_id = (SELECT auth.uid())
      AND au.role = 'founder'
      AND p.role = 'founder'
      AND p.is_active = TRUE
  ) THEN
    RAISE EXCEPTION 'Founder permission denied';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables t
    WHERE t.table_schema = 'public'
      AND t.table_type = 'BASE TABLE'
      AND t.table_name = p_table_name
  ) THEN
    RAISE EXCEPTION 'Table not found: %', p_table_name;
  END IF;

  IF p_table_name IN (
    'admin_users',
    'admin_logs',
    'system_settings',
    'system_status',
    'subscription_plans',
    'profiles'
  ) THEN
    RAISE EXCEPTION 'Protected table cannot be reset: %', p_table_name;
  END IF;

  EXECUTE format('SELECT COUNT(*) FROM public.%I', p_table_name)
    INTO rows_deleted;

  EXECUTE format('TRUNCATE TABLE public.%I CASCADE', p_table_name);

  INSERT INTO public.admin_logs (
    admin_user_id,
    target_user_id,
    action,
    details
  )
  VALUES (
    auth.uid(),
    auth.uid(),
    'table_reset',
    jsonb_build_object(
      'table',
      p_table_name,
      'rows_deleted',
      rows_deleted
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'table', p_table_name,
    'rows_deleted', rows_deleted
  );
END;
$function$;

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
    FROM public.admin_users au
    JOIN public.profiles p ON p.id = au.user_id
    WHERE au.user_id = (SELECT auth.uid())
      AND au.role = 'founder'
      AND p.role = 'founder'
      AND p.is_active = TRUE
  ) THEN
    RAISE EXCEPTION 'Founder permission denied';
  END IF;

  FOR tbl_name IN
    SELECT t.table_name::text
    FROM information_schema.tables t
    WHERE t.table_schema = 'public'
      AND t.table_type = 'BASE TABLE'
      AND t.table_name != ALL(protected_tables)
    ORDER BY t.table_name
  LOOP
    EXECUTE format('SELECT COUNT(*) FROM public.%I', tbl_name)
      INTO tbl_count;

    IF tbl_count > 0 THEN
      total_deleted := total_deleted + tbl_count;
      reset_tables := array_append(reset_tables, tbl_name);
    END IF;

    EXECUTE format('TRUNCATE TABLE public.%I CASCADE', tbl_name);
  END LOOP;

  INSERT INTO public.admin_logs (
    admin_user_id,
    target_user_id,
    action,
    details
  )
  VALUES (
    auth.uid(),
    auth.uid(),
    'all_data_reset',
    jsonb_build_object(
      'total_rows_deleted',
      total_deleted,
      'tables_reset',
      array_length(reset_tables, 1)
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'total_rows_deleted', total_deleted,
    'tables_reset', to_jsonb(reset_tables)
  );
END;
$function$;

REVOKE ALL ON FUNCTION private.admin_reset_table(text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.admin_reset_table(text)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION private.admin_reset_all_user_data()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.admin_reset_all_user_data()
  TO authenticated, service_role;

DROP POLICY IF EXISTS "admin_logs_update" ON public.admin_logs;
DROP POLICY IF EXISTS "admin_logs_delete" ON public.admin_logs;
DROP POLICY IF EXISTS "Admins can update logs" ON public.admin_logs;
DROP POLICY IF EXISTS "Admins can delete logs" ON public.admin_logs;

REVOKE UPDATE, DELETE ON TABLE public.admin_logs FROM authenticated;
REVOKE UPDATE, DELETE ON TABLE public.admin_logs FROM anon;

ALTER TABLE public.admin_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_logs FORCE ROW LEVEL SECURITY;

COMMENT ON TABLE public.admin_logs IS
  'Admin action log. Client-visible reads/inserts are retained for current '
  'admin panel compatibility; update/delete are revoked to preserve append-only '
  'semantics until server-side audit triggers fully replace client log writes.';
