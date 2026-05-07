-- Manage private user-scoped storage buckets and policies in migrations.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  (
    'bird-photos',
    'bird-photos',
    false,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic']::text[]
  ),
  (
    'egg-photos',
    'egg-photos',
    false,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic']::text[]
  ),
  (
    'chick-photos',
    'chick-photos',
    false,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic']::text[]
  ),
  (
    'community-photos',
    'community-photos',
    false,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic']::text[]
  ),
  (
    'backups',
    'backups',
    false,
    52428800,
    NULL::text[]
  )
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Users can select own bird-photos" ON storage.objects;
CREATE POLICY "Users can select own bird-photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'bird-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can insert own bird-photos" ON storage.objects;
CREATE POLICY "Users can insert own bird-photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'bird-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can update own bird-photos" ON storage.objects;
CREATE POLICY "Users can update own bird-photos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'bird-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'bird-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can delete own bird-photos" ON storage.objects;
CREATE POLICY "Users can delete own bird-photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'bird-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can select own egg-photos" ON storage.objects;
CREATE POLICY "Users can select own egg-photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'egg-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can insert own egg-photos" ON storage.objects;
CREATE POLICY "Users can insert own egg-photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'egg-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can update own egg-photos" ON storage.objects;
CREATE POLICY "Users can update own egg-photos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'egg-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'egg-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can delete own egg-photos" ON storage.objects;
CREATE POLICY "Users can delete own egg-photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'egg-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can select own chick-photos" ON storage.objects;
CREATE POLICY "Users can select own chick-photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'chick-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can insert own chick-photos" ON storage.objects;
CREATE POLICY "Users can insert own chick-photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'chick-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can update own chick-photos" ON storage.objects;
CREATE POLICY "Users can update own chick-photos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'chick-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'chick-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can delete own chick-photos" ON storage.objects;
CREATE POLICY "Users can delete own chick-photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'chick-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can select own community-photos" ON storage.objects;
CREATE POLICY "Users can select own community-photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'community-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can insert own community-photos" ON storage.objects;
CREATE POLICY "Users can insert own community-photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'community-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can update own community-photos" ON storage.objects;
CREATE POLICY "Users can update own community-photos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'community-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'community-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can delete own community-photos" ON storage.objects;
CREATE POLICY "Users can delete own community-photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'community-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can select own backups" ON storage.objects;
CREATE POLICY "Users can select own backups"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'backups'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can insert own backups" ON storage.objects;
CREATE POLICY "Users can insert own backups"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'backups'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can update own backups" ON storage.objects;
CREATE POLICY "Users can update own backups"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'backups'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'backups'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can delete own backups" ON storage.objects;
CREATE POLICY "Users can delete own backups"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'backups'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
