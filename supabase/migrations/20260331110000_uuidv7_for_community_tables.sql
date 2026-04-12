-- =============================================
-- Migrate ALL table PK defaults from UUIDv4 to UUIDv7.
-- UUIDv7 is time-ordered, which means:
--   1. B-tree inserts are sequential (no random page splits / fragmentation)
--   2. Natural chronological ordering without extra index
--   3. Existing UUIDv4 rows remain valid (UUIDv7 is backward-compatible)
--
-- Note: Client-side Dart code also generates UUIDs; the matching Dart
-- change switches Uuid().v4() → Uuid().v7() across all repositories.
--
-- SKIP: pg_uuidv7 extension is not available on all Supabase instances.
-- Client-side UUIDs (Dart uuid package) handle v7 generation.
-- Server-side defaults remain gen_random_uuid() (v4) which is fine.
-- =============================================

-- No-op: pg_uuidv7 is not available on this Supabase instance.
-- UUIDv7 generation is handled client-side by Dart uuid package.
SELECT 1;
