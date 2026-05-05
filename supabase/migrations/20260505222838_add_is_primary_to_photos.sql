-- Keep the remote photos table aligned with the local Drift Photo model.
--
-- The app already tracks Photo.isPrimary locally and uses it in admin exports
-- and detail views. Persisting it remotely prevents sync from dropping that
-- state and removes the need for admin screens to infer primary photos from
-- sort_order.

ALTER TABLE public.photos
  ADD COLUMN IF NOT EXISTS is_primary boolean NOT NULL DEFAULT false;

WITH ranked_photos AS (
  SELECT
    id,
    row_number() OVER (
      PARTITION BY user_id, entity_type, entity_id
      ORDER BY sort_order ASC, created_at ASC, id ASC
    ) AS rank
  FROM public.photos
  WHERE is_deleted = false
)
UPDATE public.photos AS photos
SET is_primary = true
FROM ranked_photos
WHERE photos.id = ranked_photos.id
  AND ranked_photos.rank = 1
  AND photos.is_primary = false;

CREATE INDEX IF NOT EXISTS idx_photos_entity_primary
  ON public.photos (user_id, entity_type, entity_id, is_primary)
  WHERE is_deleted = false;

COMMENT ON COLUMN public.photos.is_primary IS
  'Primary gallery photo marker mirrored from the local Drift Photo.isPrimary field.';
