-- =============================================
-- Automated DB monitoring with pg_cron.
--
-- Creates a monitoring table and scheduled jobs that:
--   1. Capture slow query snapshots every hour
--   2. Log table bloat and autovacuum health daily
--   3. Track connection usage patterns hourly
--   4. Auto-clean monitoring data older than 30 days
-- =============================================

-- Enable pg_cron (Supabase supports this natively)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Grant pg_cron usage to postgres role
GRANT USAGE ON SCHEMA cron TO postgres;

-- =============================================
-- Monitoring tables
-- =============================================

CREATE TABLE IF NOT EXISTS public.db_monitoring_snapshots (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  snapshot_type text NOT NULL, -- 'slow_queries', 'table_health', 'connections'
  data jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Index for time-based queries (cleanup, dashboard, trend analysis)
CREATE INDEX IF NOT EXISTS idx_monitoring_created
  ON public.db_monitoring_snapshots (created_at DESC);

-- RLS: admin-only access
ALTER TABLE public.db_monitoring_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.db_monitoring_snapshots FORCE ROW LEVEL SECURITY;

CREATE POLICY "Admin read monitoring"
  ON public.db_monitoring_snapshots
  FOR SELECT
  USING ((SELECT public.is_admin()));

-- INSERT restricted to postgres/service_role only (cron jobs run as postgres
-- via SECURITY DEFINER functions). Revoking INSERT from authenticated/anon
-- prevents any user from flooding the monitoring table.
REVOKE INSERT ON public.db_monitoring_snapshots FROM authenticated, anon;
GRANT INSERT ON public.db_monitoring_snapshots TO postgres, service_role;

-- RLS INSERT policy for cron jobs: FORCE ROW LEVEL SECURITY applies RLS even
-- to the table owner, so SECURITY DEFINER functions (running as postgres) need
-- an explicit INSERT policy — otherwise their INSERTs would be silently blocked.
CREATE POLICY "System insert monitoring"
  ON public.db_monitoring_snapshots
  FOR INSERT
  TO postgres, service_role
  WITH CHECK (true);

-- =============================================
-- 1. Slow query snapshot (hourly)
-- =============================================
CREATE OR REPLACE FUNCTION public.capture_slow_queries()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.db_monitoring_snapshots (snapshot_type, data)
  SELECT
    'slow_queries',
    jsonb_build_object(
      'queries', COALESCE(jsonb_agg(q), '[]'::jsonb)
    )
  FROM (
    SELECT jsonb_build_object(
      'calls', calls,
      'total_time_ms', ROUND(total_exec_time::numeric, 2),
      'mean_time_ms', ROUND(mean_exec_time::numeric, 2),
      'query', LEFT(query, 200)
    ) AS q
    FROM extensions.pg_stat_statements
    WHERE mean_exec_time > 50
      AND calls > 3
      AND query NOT LIKE '%pg_stat%'
    ORDER BY total_exec_time DESC
    LIMIT 15
  ) sub;
END;
$$;

-- =============================================
-- 2. Table health snapshot (daily)
-- =============================================
CREATE OR REPLACE FUNCTION public.capture_table_health()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.db_monitoring_snapshots (snapshot_type, data)
  SELECT
    'table_health',
    jsonb_build_object(
      'tables', COALESCE(jsonb_agg(t), '[]'::jsonb)
    )
  FROM (
    SELECT jsonb_build_object(
      'table_name', relname,
      'live_rows', n_live_tup,
      'dead_rows', n_dead_tup,
      'dead_pct', CASE WHEN n_live_tup > 0
        THEN ROUND(100.0 * n_dead_tup / (n_live_tup + n_dead_tup), 1)
        ELSE 0 END,
      'last_vacuum', last_vacuum,
      'last_autovacuum', last_autovacuum,
      'last_analyze', last_autoanalyze
    ) AS t
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
    ORDER BY n_dead_tup DESC
    LIMIT 30
  ) sub;
END;
$$;

-- =============================================
-- 3. Connection usage snapshot (hourly)
-- =============================================
CREATE OR REPLACE FUNCTION public.capture_connection_stats()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.db_monitoring_snapshots (snapshot_type, data)
  SELECT
    'connections',
    jsonb_build_object(
      'states', COALESCE(jsonb_agg(c), '[]'::jsonb),
      'total', (SELECT count(*) FROM pg_stat_activity WHERE backend_type = 'client backend'),
      'max_connections', current_setting('max_connections')::int
    )
  FROM (
    SELECT jsonb_build_object(
      'state', COALESCE(state, 'unknown'),
      'count', count(*)
    ) AS c
    FROM pg_stat_activity
    WHERE backend_type = 'client backend'
    GROUP BY state
  ) sub;
END;
$$;

-- =============================================
-- 4. Cleanup old monitoring data (daily)
-- =============================================
CREATE OR REPLACE FUNCTION public.cleanup_monitoring_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  DELETE FROM public.db_monitoring_snapshots
  WHERE created_at < now() - INTERVAL '30 days';
END;
$$;

-- =============================================
-- Restrict EXECUTE to postgres/service_role only (prevents any
-- authenticated user from invoking monitoring functions via RPC).
-- =============================================
REVOKE EXECUTE ON FUNCTION public.capture_slow_queries() FROM PUBLIC, authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.capture_table_health() FROM PUBLIC, authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.capture_connection_stats() FROM PUBLIC, authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.cleanup_monitoring_data() FROM PUBLIC, authenticated, anon;

-- Explicitly grant to postgres and service_role (REVOKE FROM PUBLIC removes
-- the default grant; without this, service_role loses access).
GRANT EXECUTE ON FUNCTION public.capture_slow_queries() TO postgres, service_role;
GRANT EXECUTE ON FUNCTION public.capture_table_health() TO postgres, service_role;
GRANT EXECUTE ON FUNCTION public.capture_connection_stats() TO postgres, service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_monitoring_data() TO postgres, service_role;

-- =============================================
-- Schedule cron jobs
-- =============================================

-- Unschedule existing jobs first (idempotency: prevents duplicates on re-run)
SELECT cron.unschedule(jobname)
  FROM cron.job
  WHERE jobname IN (
    'capture-slow-queries',
    'capture-table-health',
    'capture-connection-stats',
    'cleanup-monitoring-data'
  );

-- Slow queries: every hour at minute 5
SELECT cron.schedule(
  'capture-slow-queries',
  '5 * * * *',
  'SELECT public.capture_slow_queries()'
);

-- Table health: daily at 03:00 UTC
SELECT cron.schedule(
  'capture-table-health',
  '0 3 * * *',
  'SELECT public.capture_table_health()'
);

-- Connection stats: every hour at minute 10
SELECT cron.schedule(
  'capture-connection-stats',
  '10 * * * *',
  'SELECT public.capture_connection_stats()'
);

-- Cleanup: daily at 04:00 UTC
SELECT cron.schedule(
  'cleanup-monitoring-data',
  '0 4 * * *',
  'SELECT public.cleanup_monitoring_data()'
);
