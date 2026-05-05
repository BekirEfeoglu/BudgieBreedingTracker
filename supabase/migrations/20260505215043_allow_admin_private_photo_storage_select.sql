-- Allow admins to create signed URLs for user photo buckets.
--
-- The admin user-detail screen reads user content through RLS-protected public
-- tables, then needs Storage SELECT permission to renew expired signed URLs for
-- private photo buckets. Owners keep their existing own-path policies; this
-- policy only adds read access for admin/founder profiles.

DROP POLICY IF EXISTS "Admins can select private user photos" ON storage.objects;

CREATE POLICY "Admins can select private user photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id IN ('bird-photos', 'egg-photos', 'chick-photos')
  AND (SELECT public.is_admin())
);
