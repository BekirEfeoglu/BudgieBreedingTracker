-- =============================================
-- Connection and statement timeout configuration.
--
-- Prevents idle connections from hogging slots and
-- runaway queries from blocking other transactions.
-- =============================================

-- 1. Idle transaction timeout: abort transactions that sit idle > 30s.
-- Prevents lock hogging from abandoned client connections.
ALTER DATABASE postgres SET idle_in_transaction_session_timeout = '30s';

-- 2. Statement timeout: kill individual queries that run > 120s.
-- Set to 120s to accommodate sync pull operations:
--   - fetchUpdatedSince: up to 5000 rows per query
--   - fetchAllPaginated: 500 rows per page cursor query
--   - Individual entity push (upsert): completes in <1s
-- 120s provides safe headroom while catching true runaway queries.
-- SyncOrchestrator has a separate 5-minute client-side timeout that
-- covers the entire multi-query sync cycle (not individual statements).
ALTER DATABASE postgres SET statement_timeout = '120s';

-- 3. Lock timeout: don't wait more than 10s for a row/table lock.
-- Prevents cascading lock waits during concurrent sync operations.
ALTER DATABASE postgres SET lock_timeout = '10s';
