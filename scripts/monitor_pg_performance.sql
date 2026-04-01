-- =============================================================================
-- PostgreSQL Performance Monitoring Queries
-- =============================================================================
-- Run these queries against the Supabase SQL Editor to diagnose performance.
-- Requires pg_stat_statements extension (enabled in migration 20260331100000).
--
-- Usage:
--   1. Connect via Supabase Dashboard > SQL Editor
--   2. Run sections as needed
--   3. Reset stats after optimization: SELECT pg_stat_statements_reset();
--
-- Sections:
--   A. Top 10 Slowest Queries (by total execution time)
--   B. Top 10 Most Frequent Queries
--   C. Queries with High Mean Time (> 100ms)
--   D. Cache Hit Ratio (target: > 99%)
--   E. Index Usage Stats (find unused or missing indexes)
--   F. Table Bloat & Autovacuum Status
--   G. Active Connections by State
--   H. Long-Running Queries (> 30s)
--   I. Missing Foreign Key Indexes
--   J. RLS Policy Performance Check
-- =============================================================================


-- =============================================================================
-- A. Top 10 Slowest Queries (by total execution time)
-- =============================================================================
-- These consume the most cumulative DB time. Optimize these first.
SELECT
  calls,
  ROUND(total_exec_time::NUMERIC, 2) AS total_time_ms,
  ROUND(mean_exec_time::NUMERIC, 2) AS mean_time_ms,
  ROUND((100 * total_exec_time / NULLIF(SUM(total_exec_time) OVER(), 0))::NUMERIC, 2) AS pct_total,
  LEFT(query, 120) AS query_preview
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat%'
ORDER BY total_exec_time DESC
LIMIT 10;


-- =============================================================================
-- B. Top 10 Most Frequent Queries
-- =============================================================================
-- High-frequency queries benefit most from even small optimizations.
SELECT
  calls,
  ROUND(mean_exec_time::NUMERIC, 2) AS mean_time_ms,
  ROUND(total_exec_time::NUMERIC, 2) AS total_time_ms,
  LEFT(query, 120) AS query_preview
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat%'
ORDER BY calls DESC
LIMIT 10;


-- =============================================================================
-- C. Queries with High Mean Time (> 100ms)
-- =============================================================================
-- Candidates for index optimization or query rewriting.
SELECT
  calls,
  ROUND(mean_exec_time::NUMERIC, 2) AS mean_time_ms,
  ROUND(total_exec_time::NUMERIC, 2) AS total_time_ms,
  LEFT(query, 150) AS query_preview
FROM pg_stat_statements
WHERE mean_exec_time > 100
  AND calls > 5
ORDER BY mean_exec_time DESC
LIMIT 20;


-- =============================================================================
-- D. Cache Hit Ratio (target: > 99%)
-- =============================================================================
-- If below 99%, consider increasing shared_buffers or optimizing queries.
SELECT
  'index hit ratio' AS metric,
  ROUND(
    100 * SUM(idx_blks_hit) / NULLIF(SUM(idx_blks_hit + idx_blks_read), 0), 2
  ) AS ratio_pct
FROM pg_statio_user_indexes

UNION ALL

SELECT
  'table hit ratio',
  ROUND(
    100 * SUM(heap_blks_hit) / NULLIF(SUM(heap_blks_hit + heap_blks_read), 0), 2
  )
FROM pg_statio_user_tables;


-- =============================================================================
-- E. Index Usage Stats (find unused or missing indexes)
-- =============================================================================
-- Unused indexes waste storage and slow writes. Remove if idx_scan = 0.
SELECT
  schemaname || '.' || relname AS table_name,
  indexrelname AS index_name,
  idx_scan AS times_used,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexrelname NOT LIKE '%pkey%'
  AND indexrelname NOT LIKE '%unique%'
ORDER BY pg_relation_size(indexrelid) DESC
LIMIT 20;


-- =============================================================================
-- F. Table Bloat & Autovacuum Status
-- =============================================================================
-- Tables that haven't been vacuumed recently may have bloated indexes.
SELECT
  relname AS table_name,
  n_live_tup AS live_rows,
  n_dead_tup AS dead_rows,
  CASE WHEN n_live_tup > 0
    THEN ROUND(100.0 * n_dead_tup / (n_live_tup + n_dead_tup), 1)
    ELSE 0
  END AS dead_pct,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze
FROM pg_stat_user_tables
WHERE n_dead_tup > 100
ORDER BY n_dead_tup DESC
LIMIT 20;


-- =============================================================================
-- G. Active Connections by State
-- =============================================================================
-- Monitor connection usage. If idle connections dominate, check pooling.
SELECT
  state,
  COUNT(*) AS count,
  ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER(), 0), 1) AS pct
FROM pg_stat_activity
WHERE backend_type = 'client backend'
GROUP BY state
ORDER BY count DESC;


-- =============================================================================
-- H. Long-Running Queries (> 30s)
-- =============================================================================
-- Kill blockers: SELECT pg_terminate_backend(pid);
SELECT
  pid,
  NOW() - pg_stat_activity.query_start AS duration,
  state,
  LEFT(query, 120) AS query_preview
FROM pg_stat_activity
WHERE state != 'idle'
  AND NOW() - pg_stat_activity.query_start > INTERVAL '30 seconds'
  AND backend_type = 'client backend'
ORDER BY duration DESC;


-- =============================================================================
-- I. Missing Foreign Key Indexes
-- =============================================================================
-- FK columns without indexes cause slow JOINs and CASCADE operations.
SELECT
  conrelid::regclass AS table_name,
  a.attname AS fk_column,
  confrelid::regclass AS referenced_table
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid AND a.attnum = ANY(i.indkey)
  )
ORDER BY conrelid::regclass::text;


-- =============================================================================
-- J. RLS Policy Performance Check
-- =============================================================================
-- Lists all RLS policies; check for bare auth.uid() calls (should use select wrapper).
SELECT
  schemaname,
  tablename,
  policyname,
  CASE
    WHEN qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%'
    THEN 'WARNING: bare auth.uid()'
    ELSE 'OK: optimized'
  END AS performance_status
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
