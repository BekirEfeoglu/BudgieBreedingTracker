-- Consolidate + optimize the 20 per-bucket storage.objects policies created in
-- 20260508020000 into one policy per action. Two Supabase linter fixes:
--   * auth_rls_initplan (0003): raw auth.uid() re-evaluates per row; wrapping in
--     (select auth.uid()) lets the planner evaluate it once (initplan).
--   * multiple_permissive_policies (0006): 5 per-bucket policies per action
--     (authenticated SELECT/INSERT/UPDATE/DELETE) collapse to one each via
--     bucket_id IN (...).
--
-- Effective access is identical: an authenticated user reaches objects whose
-- first path segment equals their uid, within the private user-scoped buckets.
--
-- Idempotent: DROP POLICY IF EXISTS for both the old per-bucket names and the
-- new consolidated names before CREATE.

-- 1. Drop the 20 per-bucket policies. -----------------------------------------
DROP POLICY IF EXISTS "Users can select own bird-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can insert own bird-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own bird-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own bird-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can select own egg-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can insert own egg-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own egg-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own egg-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can select own chick-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can insert own chick-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own chick-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own chick-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can select own community-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can insert own community-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own community-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own community-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can select own backups" ON storage.objects;
DROP POLICY IF EXISTS "Users can insert own backups" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own backups" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own backups" ON storage.objects;

-- 2. One consolidated, initplan-optimized policy per action. -------------------
DROP POLICY IF EXISTS "Users can read own private bucket objects" ON storage.objects;
CREATE POLICY "Users can read own private bucket objects"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id IN ('bird-photos', 'egg-photos', 'chick-photos', 'community-photos', 'backups')
  AND (storage.foldername(name))[1] = (select auth.uid())::text
);

DROP POLICY IF EXISTS "Users can insert own private bucket objects" ON storage.objects;
CREATE POLICY "Users can insert own private bucket objects"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id IN ('bird-photos', 'egg-photos', 'chick-photos', 'community-photos', 'backups')
  AND (storage.foldername(name))[1] = (select auth.uid())::text
);

DROP POLICY IF EXISTS "Users can update own private bucket objects" ON storage.objects;
CREATE POLICY "Users can update own private bucket objects"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id IN ('bird-photos', 'egg-photos', 'chick-photos', 'community-photos', 'backups')
  AND (storage.foldername(name))[1] = (select auth.uid())::text
)
WITH CHECK (
  bucket_id IN ('bird-photos', 'egg-photos', 'chick-photos', 'community-photos', 'backups')
  AND (storage.foldername(name))[1] = (select auth.uid())::text
);

DROP POLICY IF EXISTS "Users can delete own private bucket objects" ON storage.objects;
CREATE POLICY "Users can delete own private bucket objects"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id IN ('bird-photos', 'egg-photos', 'chick-photos', 'community-photos', 'backups')
  AND (storage.foldername(name))[1] = (select auth.uid())::text
);
