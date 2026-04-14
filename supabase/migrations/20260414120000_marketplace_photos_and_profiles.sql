-- 1. Create photos storage bucket for marketplace images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'photos',
  'photos',
  true,
  10485760,  -- 10MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic']
)
ON CONFLICT (id) DO NOTHING;

-- RLS policies for marketplace-images path
CREATE POLICY "Public read marketplace images"
ON storage.objects FOR SELECT
USING (bucket_id = 'photos');

CREATE POLICY "Users can upload own marketplace images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'photos'
  AND (storage.foldername(name))[1] = 'marketplace-images'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

CREATE POLICY "Users can delete own marketplace images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'photos'
  AND (storage.foldername(name))[1] = 'marketplace-images'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- 2. Add username and avatar_url columns to marketplace_listings
-- Denormalized for read performance (avoids JOIN on every listing query).
-- Updated by trigger when profile changes.
ALTER TABLE marketplace_listings
  ADD COLUMN IF NOT EXISTS username TEXT,
  ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Backfill from profiles
UPDATE marketplace_listings ml
SET
  username = COALESCE(p.display_name, p.full_name, split_part(p.email, '@', 1)),
  avatar_url = p.avatar_url
FROM profiles p
WHERE ml.user_id = p.id
  AND ml.username IS NULL;

-- Trigger to keep denormalized columns in sync
CREATE OR REPLACE FUNCTION sync_marketplace_listing_profile()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE marketplace_listings
  SET
    username = COALESCE(NEW.display_name, NEW.full_name, split_part(NEW.email, '@', 1)),
    avatar_url = NEW.avatar_url
  WHERE user_id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER marketplace_profile_sync
  AFTER UPDATE OF display_name, full_name, avatar_url ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION sync_marketplace_listing_profile();

-- 3. Add marketplace_listings to free tier validation
-- (Edge function LIMITS config updated separately in index.ts)
-- Add composite index for free tier count query
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_user_active
  ON marketplace_listings(user_id, status)
  WHERE is_deleted = false;
