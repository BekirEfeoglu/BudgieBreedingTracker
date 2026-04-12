-- =============================================
-- Cron job verification RPC and initial data seed.
--
-- Provides an admin-callable function to verify pg_cron jobs are
-- scheduled and running, plus seeds initial monitoring data to
-- validate the pipeline immediately after deployment.
-- =============================================

-- 1. Verification RPC: returns status of all monitoring cron jobs.
-- Call via: supabase.rpc('verify_monitoring_cron_jobs')
CREATE OR REPLACE FUNCTION public.verify_monitoring_cron_jobs()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  result jsonb;
  job_count int;
  latest_snapshot timestamptz;
  snapshot_count int;
BEGIN
  -- Check if user is admin
  IF NOT (SELECT public.is_admin()) THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  -- Count scheduled monitoring jobs
  SELECT count(*) INTO job_count
  FROM cron.job
  WHERE jobname IN (
    'capture-slow-queries',
    'capture-table-health',
    'capture-connection-stats',
    'cleanup-monitoring-data'
  );

  -- Get latest snapshot timestamp
  SELECT max(created_at) INTO latest_snapshot
  FROM public.db_monitoring_snapshots;

  -- Count total snapshots
  SELECT count(*) INTO snapshot_count
  FROM public.db_monitoring_snapshots;

  -- Build detailed job status
  SELECT jsonb_build_object(
    'status', CASE
      WHEN job_count = 4 THEN 'ok'
      WHEN job_count > 0 THEN 'partial'
      ELSE 'missing'
    END,
    'scheduled_jobs', job_count,
    'expected_jobs', 4,
    'total_snapshots', snapshot_count,
    'latest_snapshot_at', latest_snapshot,
    'jobs', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'name', jobname,
        'schedule', schedule,
        'active', active,
        'database', database
      ))
      FROM cron.job
      WHERE jobname IN (
        'capture-slow-queries',
        'capture-table-health',
        'capture-connection-stats',
        'cleanup-monitoring-data'
      )
    ), '[]'::jsonb)
  ) INTO result;

  RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_monitoring_cron_jobs() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.verify_monitoring_cron_jobs() FROM anon, public;

-- 2. Seed initial monitoring data to validate pipeline.
-- This runs the capture functions once so the admin dashboard
-- shows data immediately without waiting for the first cron tick.
SELECT public.capture_slow_queries();
SELECT public.capture_table_health();
SELECT public.capture_connection_stats();
