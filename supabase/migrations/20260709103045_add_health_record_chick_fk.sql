-- Add optional chick linkage for health records.
--
-- Health records can now be global, bird-linked, or chick-linked. The FK is
-- nullable and uses ON DELETE SET NULL to preserve medical history when a chick
-- row is removed or promoted elsewhere.

ALTER TABLE public.health_records
  ADD COLUMN IF NOT EXISTS chick_id UUID REFERENCES public.chicks(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_health_records_chick_id
  ON public.health_records(chick_id);

CREATE INDEX IF NOT EXISTS idx_health_records_chick_deleted
  ON public.health_records(chick_id, is_deleted)
  WHERE chick_id IS NOT NULL;
