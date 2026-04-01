-- =============================================
-- Enable pg_stat_statements for query performance monitoring
-- and add partial indexes for high-traffic query patterns.
-- =============================================

-- 1. pg_stat_statements: tracks execution stats for all queries.
-- Use pg_stat_statements to find slow / frequent queries:
--   SELECT calls, mean_exec_time, query FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 2. Partial indexes for is_deleted = false (covers 95%+ of user queries).
-- These are smaller and faster than full composite indexes because they
-- exclude soft-deleted rows that are never queried by normal users.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_birds_active
  ON birds (user_id) WHERE is_deleted = false;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_eggs_active
  ON eggs (user_id) WHERE is_deleted = false;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_chicks_active
  ON chicks (user_id) WHERE is_deleted = false;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_breeding_pairs_active
  ON breeding_pairs (user_id) WHERE is_deleted = false;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_events_active
  ON events (user_id) WHERE is_deleted = false;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_health_records_active
  ON health_records (user_id) WHERE is_deleted = false;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_clutches_active
  ON clutches (user_id) WHERE is_deleted = false;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_nests_active
  ON nests (user_id) WHERE is_deleted = false;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_community_posts_active
  ON community_posts (user_id, created_at DESC) WHERE is_deleted = false;

-- 3. Missing GIN indexes on queryable JSONB columns.
-- genetics_history father/mother mutations are used in search/filter queries.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_genetics_history_father_mutations_gin
  ON genetics_history USING gin (father_mutations jsonb_path_ops);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_genetics_history_mother_mutations_gin
  ON genetics_history USING gin (mother_mutations jsonb_path_ops);

-- community_posts tags for future tag-based filtering (@> containment).
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_community_posts_tags_gin
  ON community_posts USING gin (tags jsonb_path_ops);
