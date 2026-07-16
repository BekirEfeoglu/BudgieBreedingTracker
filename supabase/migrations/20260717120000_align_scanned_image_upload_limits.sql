-- Align every safety-scanned image bucket with the 2 MiB raw moderation cap.
-- Client resize/quality is best-effort; bucket limits remain the final size
-- backstop for direct Storage requests. Backups keep their separate 50 MiB
-- contract and are intentionally excluded.
UPDATE storage.buckets
SET file_size_limit = 2097152
WHERE id IN (
  'bird-photos',
  'egg-photos',
  'chick-photos',
  'avatars',
  'community-photos',
  'photos',
  'message-photos'
);
