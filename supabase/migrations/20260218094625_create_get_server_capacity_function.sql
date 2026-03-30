
CREATE OR REPLACE FUNCTION public.get_server_capacity()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  result jsonb;
  v_db_size bigint;
  v_active_conns int;
  v_total_conns int;
  v_max_conns int;
  v_cache_hit_ratio float;
  v_total_rows bigint;
  v_index_hit_ratio float;
  v_tables jsonb;
  v_caller_id uuid;
BEGIN
  -- Admin check: only admin users can call this
  v_caller_id := auth.uid();
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.admin_users WHERE user_id = v_caller_id::text
  ) THEN
    RAISE EXCEPTION 'Admin permission denied';
  END IF;

  -- Database size
  SELECT pg_database_size(current_database()) INTO v_db_size;

  -- Connection counts
  SELECT count(*) FILTER (WHERE state = 'active'),
         count(*)
  INTO v_active_conns, v_total_conns
  FROM pg_stat_activity
  WHERE datname = current_database();

  -- Max connections
  SELECT current_setting('max_connections')::int INTO v_max_conns;

  -- Cache hit ratio
  SELECT CASE WHEN (blks_hit + blks_read) = 0 THEN 100.0
              ELSE round((blks_hit::numeric / (blks_hit + blks_read)::numeric) * 100, 2)
         END
  INTO v_cache_hit_ratio
  FROM pg_stat_database
  WHERE datname = current_database();

  -- Total rows across all user tables
  SELECT COALESCE(sum(n_live_tup), 0)
  INTO v_total_rows
  FROM pg_stat_user_tables
  WHERE schemaname = 'public';

  -- Index hit ratio (across all user tables)
  SELECT CASE WHEN COALESCE(sum(idx_scan + seq_scan), 0) = 0 THEN 100.0
              ELSE round((sum(idx_scan)::numeric / NULLIF(sum(idx_scan + seq_scan), 0)::numeric) * 100, 2)
         END
  INTO v_index_hit_ratio
  FROM pg_stat_user_tables
  WHERE schemaname = 'public';

  -- Table details (public schema only, ordered by size desc)
  SELECT COALESCE(jsonb_agg(t ORDER BY (t->>'size_bytes')::bigint DESC), '[]'::jsonb)
  INTO v_tables
  FROM (
    SELECT jsonb_build_object(
      'name', relname,
      'size_bytes', pg_total_relation_size(relid),
      'row_count', n_live_tup,
      'dead_tuple_count', n_dead_tup,
      'dead_tuple_ratio', CASE WHEN (n_live_tup + n_dead_tup) = 0 THEN 0.0
                               ELSE round((n_dead_tup::numeric / (n_live_tup + n_dead_tup)::numeric) * 100, 2)
                          END,
      'last_vacuum', COALESCE(to_char(last_autovacuum, 'YYYY-MM-DD HH24:MI'), to_char(last_vacuum, 'YYYY-MM-DD HH24:MI')),
      'last_analyze', COALESCE(to_char(last_autoanalyze, 'YYYY-MM-DD HH24:MI'), to_char(last_analyze, 'YYYY-MM-DD HH24:MI'))
    ) AS t
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
  ) sub;

  -- Build result
  result := jsonb_build_object(
    'database_size_bytes', v_db_size,
    'active_connections', v_active_conns,
    'total_connections', v_total_conns,
    'max_connections', v_max_conns,
    'cache_hit_ratio', v_cache_hit_ratio,
    'total_rows', v_total_rows,
    'index_hit_ratio', v_index_hit_ratio,
    'tables', v_tables
  );

  RETURN result;
END;
$$;

-- Grant execute to authenticated users (admin check is inside the function)
GRANT EXECUTE ON FUNCTION public.get_server_capacity() TO authenticated;
;
