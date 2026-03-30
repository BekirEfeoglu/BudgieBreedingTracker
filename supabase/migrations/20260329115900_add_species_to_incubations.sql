ALTER TABLE public.incubations
ADD COLUMN IF NOT EXISTS species text NOT NULL DEFAULT 'budgie';

UPDATE public.incubations
SET species = COALESCE(
  (
    SELECT b.species
    FROM public.breeding_pairs bp
    JOIN public.birds b ON b.id = bp.male_id
    WHERE bp.id = incubations.breeding_pair_id
    LIMIT 1
  ),
  'budgie'
)
WHERE species IS NULL OR species = 'budgie';

COMMENT ON COLUMN public.incubations.species IS
'Species profile key for incubation-specific rules such as expected hatch duration.';
