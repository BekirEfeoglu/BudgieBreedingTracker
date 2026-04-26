-- Security hardening follow-up
-- - Prevent public listing of avatar and marketplace storage objects.
-- - Keep public URL serving intact for public buckets; list/delete operations
--   are limited to the authenticated owner's path.

DROP POLICY IF EXISTS "Scoped avatar read" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can list own avatar objects" ON storage.objects;

CREATE POLICY "Users can list own avatar objects"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
);

DROP POLICY IF EXISTS "Scoped photos read" ON storage.objects;
DROP POLICY IF EXISTS "Public read marketplace images" ON storage.objects;
DROP POLICY IF EXISTS "Users can list own marketplace images" ON storage.objects;

CREATE POLICY "Users can list own marketplace images"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'photos'
  AND (storage.foldername(name))[1] = 'marketplace-images'
  AND (storage.foldername(name))[2] = (SELECT auth.uid())::text
);

DROP POLICY IF EXISTS "Users can update own marketplace images" ON storage.objects;

CREATE POLICY "Users can update own marketplace images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'photos'
  AND (storage.foldername(name))[1] = 'marketplace-images'
  AND (storage.foldername(name))[2] = (SELECT auth.uid())::text
)
WITH CHECK (
  bucket_id = 'photos'
  AND (storage.foldername(name))[1] = 'marketplace-images'
  AND (storage.foldername(name))[2] = (SELECT auth.uid())::text
);
