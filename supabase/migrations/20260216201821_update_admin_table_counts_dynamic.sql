
-- RPC fonksiyonunu dinamik hale getir: tüm public tabloları otomatik sayar
CREATE OR REPLACE FUNCTION admin_get_table_counts()
RETURNS TABLE(table_name text, row_count bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  tbl_name text;
  tbl_count bigint;
BEGIN
  -- Sadece admin kontrolü
  IF NOT EXISTS (
    SELECT 1 FROM admin_users WHERE user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Admin permission denied';
  END IF;

  -- Tüm public tabloları dinamik olarak say
  FOR tbl_name IN
    SELECT t.table_name::text
    FROM information_schema.tables t
    WHERE t.table_schema = 'public'
      AND t.table_type = 'BASE TABLE'
    ORDER BY t.table_name
  LOOP
    EXECUTE format('SELECT COUNT(*) FROM public.%I', tbl_name) INTO tbl_count;
    table_name := tbl_name;
    row_count := tbl_count;
    RETURN NEXT;
  END LOOP;
END;
$$;
;
