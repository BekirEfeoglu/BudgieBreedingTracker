-- One hatched egg may map to at most one active chick.
--
-- Preserve historical breeder data while repairing duplicates: the oldest
-- active chick keeps the egg link and later rows remain as unlinked chicks.
WITH ranked_active_chicks AS (
  SELECT
    id,
    row_number() OVER (
      PARTITION BY egg_id
      ORDER BY created_at ASC NULLS LAST, id ASC
    ) AS egg_rank
  FROM public.chicks
  WHERE egg_id IS NOT NULL
    AND is_deleted = false
)
UPDATE public.chicks AS chick
SET egg_id = NULL
FROM ranked_active_chicks AS ranked
WHERE chick.id = ranked.id
  AND ranked.egg_rank > 1;

CREATE UNIQUE INDEX IF NOT EXISTS idx_chicks_active_egg_unique
  ON public.chicks (egg_id)
  WHERE egg_id IS NOT NULL
    AND is_deleted = false;
