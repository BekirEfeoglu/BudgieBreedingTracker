
-- ============================================
-- 1) Tek tablo yedekleme: tablo verisini JSON olarak döndürür
-- ============================================
CREATE OR REPLACE FUNCTION admin_export_table(p_table_name text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result jsonb;
BEGIN
  -- Admin kontrolü
  IF NOT EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Admin permission denied';
  END IF;

  -- Tablo adı doğrulama (SQL injection önleme)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE' AND table_name = p_table_name
  ) THEN
    RAISE EXCEPTION 'Table not found: %', p_table_name;
  END IF;

  EXECUTE format('SELECT COALESCE(jsonb_agg(row_to_json(t)), ''[]''::jsonb) FROM public.%I t', p_table_name) INTO result;
  
  RETURN result;
END;
$$;

-- ============================================
-- 2) Tüm tabloları yedekleme: her tablo verisini JSON objesi olarak döndürür
-- ============================================
CREATE OR REPLACE FUNCTION admin_export_all_tables()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result jsonb := '{}'::jsonb;
  tbl_name text;
  tbl_data jsonb;
BEGIN
  -- Admin kontrolü
  IF NOT EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Admin permission denied';
  END IF;

  FOR tbl_name IN
    SELECT t.table_name::text
    FROM information_schema.tables t
    WHERE t.table_schema = 'public' AND t.table_type = 'BASE TABLE'
    ORDER BY t.table_name
  LOOP
    EXECUTE format('SELECT COALESCE(jsonb_agg(row_to_json(t)), ''[]''::jsonb) FROM public.%I t', tbl_name) INTO tbl_data;
    result := result || jsonb_build_object(tbl_name, tbl_data);
  END LOOP;

  RETURN result;
END;
$$;

-- ============================================
-- 3) Tek tablo sıfırlama (TRUNCATE CASCADE)
-- ============================================
CREATE OR REPLACE FUNCTION admin_reset_table(p_table_name text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rows_deleted bigint;
  affected_tables text[];
BEGIN
  -- Admin kontrolü
  IF NOT EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Admin permission denied';
  END IF;

  -- Tablo adı doğrulama
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE' AND table_name = p_table_name
  ) THEN
    RAISE EXCEPTION 'Table not found: %', p_table_name;
  END IF;

  -- Sistem tablolarını koruma altına al (sıfırlanamaz)
  IF p_table_name IN ('admin_users', 'admin_logs', 'system_settings', 'system_status', 'subscription_plans', 'profiles') THEN
    RAISE EXCEPTION 'Protected table cannot be reset: %', p_table_name;
  END IF;

  -- Satır sayısını al
  EXECUTE format('SELECT COUNT(*) FROM public.%I', p_table_name) INTO rows_deleted;

  -- CASCADE ile sıfırla (FK bağımlılıkları da temizlenir)
  EXECUTE format('TRUNCATE TABLE public.%I CASCADE', p_table_name);

  -- Admin log'a kaydet
  INSERT INTO admin_logs (admin_user_id, target_user_id, action, details)
  VALUES (
    auth.uid(), 
    auth.uid(), 
    'table_reset', 
    format('Table "%s" reset. %s rows removed.', p_table_name, rows_deleted)
  );

  RETURN jsonb_build_object(
    'success', true,
    'table', p_table_name,
    'rows_deleted', rows_deleted
  );
END;
$$;

-- ============================================
-- 4) Tüm kullanıcı verilerini sıfırlama (sistem tabloları hariç)
-- ============================================
CREATE OR REPLACE FUNCTION admin_reset_all_user_data()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
  reset_tables text[] := '{}';
BEGIN
  -- Admin kontrolü
  IF NOT EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Admin permission denied';
  END IF;

  -- Kullanıcı veri tablolarını sıfırla (korumalı tablolar hariç)
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

  -- Admin log'a kaydet
  INSERT INTO admin_logs (admin_user_id, target_user_id, action, details)
  VALUES (
    auth.uid(),
    auth.uid(),
    'all_data_reset',
    format('All user data reset. %s rows removed from %s tables.', total_deleted, array_length(reset_tables, 1))
  );

  RETURN jsonb_build_object(
    'success', true,
    'total_rows_deleted', total_deleted,
    'tables_reset', to_jsonb(reset_tables)
  );
END;
$$;
;
