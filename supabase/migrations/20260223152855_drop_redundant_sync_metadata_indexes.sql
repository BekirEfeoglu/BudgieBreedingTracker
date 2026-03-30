
-- idx_sync_metadata_table_name: covered by idx_sync_meta_table_status (leftmost col)
-- idx_sync_metadata_status: standalone status queries not used in SyncOrchestrator
DROP INDEX IF EXISTS idx_sync_metadata_table_name;
DROP INDEX IF EXISTS idx_sync_metadata_status;
;
