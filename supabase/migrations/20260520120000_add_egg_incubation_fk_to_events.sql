-- Adds egg_id and incubation_id foreign-key columns to the events table.
--
-- Before this migration, calendar entries generated from egg-laying,
-- expected-hatch, and incubation-milestone flows carried no FK back to
-- the egg or incubation they belonged to. When the parent egg or
-- incubation was deleted, these events accumulated as permanent orphans
-- because the cleanup helpers (removeByEggIds / removeByIncubationIds)
-- had nothing to filter on.
--
-- Both columns are nullable so existing rows survive untouched. ON DELETE
-- SET NULL matches the policy already used for the other event FK
-- columns (bird_id, breeding_pair_id, chick_id). The client-side
-- repository handles soft-delete cleanup; the SET NULL here is a
-- second-line guard against orphans if the client path is ever skipped.

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS egg_id uuid NULL
    REFERENCES public.eggs(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS incubation_id uuid NULL
    REFERENCES public.incubations(id) ON DELETE SET NULL;

-- Filtered indexes keep the cleanup helpers O(log n) on accounts that
-- accumulate thousands of events across many seasons.
CREATE INDEX IF NOT EXISTS idx_events_egg_id
  ON public.events (egg_id)
  WHERE egg_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_events_incubation_id
  ON public.events (incubation_id)
  WHERE incubation_id IS NOT NULL;

COMMENT ON COLUMN public.events.egg_id IS
  'Optional FK back to the egg this calendar entry was generated for.';
COMMENT ON COLUMN public.events.incubation_id IS
  'Optional FK back to the incubation this calendar entry was generated for.';
