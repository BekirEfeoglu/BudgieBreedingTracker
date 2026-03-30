
CREATE OR REPLACE FUNCTION public.get_server_capacity()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id uuid;
  v_result jsonb;
  v_db_size bigint;
  v_active_conns int;
  v_total_conns int;
  v_max_conns int;
  v_cache_hit numeric;
  v_total_rows bigint;
  v_index_hit numeric;
  v_tables jsonb;
BEGIN
  -- Admin check: both auth.uid() and admin_users.user_id are uuid type
  v_caller_id := auth.uid();

  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.admin_users WHERE user_id = v_caller_id
  ) THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  -- Database size
  SELECT pg_database_size(current_database()) INTO v_db_size;

  -- Connections
  SELECT count(*) FILTER (WHERE state = 'active'),
         count(*)
    INTO v_active_conns, v_total_conns
    FROM pg_stat_activity;

  SELECT current_setting('max_connections')::int INTO v_max_conns;

  -- Cache hit ratio
  SELECT COALESCE(
    ROUND(100.0 * sum(blks_hit) / NULLIF(sum(blks_hit) + sum(blks_read), 0), 2),
    0
  ) INTO v_cache_hit
  FROM pg_stat_database
  WHERE datname = current_database();

  -- Total rows (estimated from pg_stat_user_tables)
  SELECT COALESCE(sum(n_live_tup), 0) INTO v_total_rows
  FROM pg_stat_user_tables;

  -- Index hit ratio
  SELECT COALESCE(
    ROUND(100.0 * sum(idx_scan) / NULLIF(sum(idx_scan) + sum(seq_scan), 0), 2),
    0
  ) INTO v_index_hit
  FROM pg_stat_user_tables;

  -- Per-table details (top 50 by size)
  SELECT COALESCE(jsonb_agg(t ORDER BY t.size_bytes DESC), '[]'::jsonb)
  INTO v_tables
  FROM (
    SELECT
      jsonb_build_object(
        'name', relname,
        'size_bytes', pg_total_relation_size(relid),
        'row_count', n_live_tup,
        'dead_tuple_count', n_dead_tup,
        'dead_tuple_ratio', CASE
          WHEN n_live_tup + n_dead_tup > 0
          THEN ROUND(100.0 * n_dead_tup / (n_live_tup + n_dead_tup), 2)
          ELSE 0
        END,
        'last_vacuum', last_autovacuum::text,
        'last_analyze', last_autoanalyze::text
      ) AS t
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
    ORDER BY pg_total_relation_size(relid) DESC
    LIMIT 50
  ) sub;

  -- Build result
  v_result := jsonb_build_object(
    'database_size_bytes', v_db_size,
    'active_connections', v_active_conns,
    'total_connections', v_total_conns,
    'max_connections', v_max_conns,
    'cache_hit_ratio', v_cache_hit,
    'total_rows', v_total_rows,
    'index_hit_ratio', v_index_hit,
    'tables', v_tables
  );

  RETURN v_result;
END;
$$;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
;
