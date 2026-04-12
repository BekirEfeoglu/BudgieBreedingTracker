ALTER TABLE public.birds
ALTER COLUMN species SET DEFAULT 'unknown';

ALTER TABLE public.incubations
ALTER COLUMN species SET DEFAULT 'unknown';

UPDATE public.birds
SET species = 'unknown'
WHERE species IS NULL OR btrim(species) = '';

UPDATE public.incubations
SET species = COALESCE(
  (
    SELECT b.species
    FROM public.breeding_pairs bp
    JOIN public.birds b ON b.id = bp.male_id
    WHERE bp.id = incubations.breeding_pair_id
    LIMIT 1
  ),
  'unknown'
)
WHERE species IS NULL OR btrim(species) = '';
