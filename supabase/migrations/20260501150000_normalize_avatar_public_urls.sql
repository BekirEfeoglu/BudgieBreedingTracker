-- =============================================================================
-- Normalize stored avatar URLs to public storage URLs
-- =============================================================================
-- The avatars bucket is public. Older client code stored 7-day signed URLs in
-- profiles.avatar_url, which later produced Storage 400s when the token
-- expired. Keep only stable public object URLs in profile data.
-- =============================================================================

UPDATE public.profiles
SET
  avatar_url = split_part(
    replace(
      avatar_url,
      '/storage/v1/object/sign/avatars/',
      '/storage/v1/object/public/avatars/'
    ),
    '?',
    1
  ),
  updated_at = NOW()
WHERE avatar_url LIKE '%/storage/v1/object/sign/avatars/%?token=%';
