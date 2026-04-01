-- =============================================
-- Weekly pg_stat_statements reset with pre-reset snapshot.
--
-- Captures a final snapshot of top slow queries before resetting
-- statistics, ensuring trend data remains clean and cumulative
-- counters don't grow unbounded.
--
-- Schedule: Every Monday at 02:00 UTC (before daily health check at 03:00).
-- =============================================

CREATE OR REPLACE FUNCTION public.weekly_stats_reset()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- 1. Capture pre-reset snapshot (preserves the week's top queries)
  INSERT INTO public.db_monitoring_snapshots (snapshot_type, data)
  SELECT
    'weekly_stats_summary',
    jsonb_build_object(
      'period', 'weekly_reset',
      'reset_at', now(),
      'top_queries_by_total_time', COALESCE((
        SELECT jsonb_agg(q)
        FROM (
          SELECT jsonb_build_object(
            'calls', calls,
            'total_time_ms', ROUND(total_exec_time::numeric, 2),
            'mean_time_ms', ROUND(mean_exec_time::numeric, 2),
            'min_time_ms', ROUND(min_exec_time::numeric, 2),
            'max_time_ms', ROUND(max_exec_time::numeric, 2),
            'rows_returned', rows,
            'query', LEFT(query, 300)
          ) AS q
          FROM extensions.pg_stat_statements
          WHERE query NOT LIKE '%pg_stat%'
          ORDER BY total_exec_time DESC
          LIMIT 20
        ) sub
      ), '[]'::jsonb),
      'top_queries_by_mean_time', COALESCE((
        SELECT jsonb_agg(q)
        FROM (
          SELECT jsonb_build_object(
            'calls', calls,
            'mean_time_ms', ROUND(mean_exec_time::numeric, 2),
            'max_time_ms', ROUND(max_exec_time::numeric, 2),
            'query', LEFT(query, 300)
          ) AS q
          FROM extensions.pg_stat_statements
          WHERE mean_exec_time > 50
            AND calls > 5
            AND query NOT LIKE '%pg_stat%'
          ORDER BY mean_exec_time DESC
          LIMIT 20
        ) sub
      ), '[]'::jsonb)
    );

  -- 2. Reset statistics for a fresh week
  PERFORM extensions.pg_stat_statements_reset();
END;
$$;

-- Restrict EXECUTE to postgres/service_role only (prevents any
-- authenticated user from resetting pg_stat_statements via RPC).
REVOKE EXECUTE ON FUNCTION public.weekly_stats_reset() FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.weekly_stats_reset() TO postgres, service_role;

-- Unschedule existing job first (idempotency: prevents duplicates on re-run)
SELECT cron.unschedule(jobname)
  FROM cron.job
  WHERE jobname = 'weekly-stats-reset';

-- Schedule: Monday 02:00 UTC
SELECT cron.schedule(
  'weekly-stats-reset',
  '0 2 * * 1',
  'SELECT public.weekly_stats_reset()'
);
