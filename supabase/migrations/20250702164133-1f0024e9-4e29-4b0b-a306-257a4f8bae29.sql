-- Fix schema inconsistencies in eggs and chicks tables (v2)

-- 1. Fix eggs table: Make clutch_id nullable since we now have incubation_id
ALTER TABLE public.eggs 
ALTER COLUMN clutch_id DROP NOT NULL;

-- 2. Fix chicks table: Make incubation_id NOT NULL for data integrity
-- First, update any existing chicks without incubation_id to link them to an incubation
UPDATE public.chicks 
SET incubation_id = (
  SELECT i.id FROM public.incubations i
  WHERE (i.male_bird_id = chicks.father_id OR i.female_bird_id = chicks.mother_id)
  ORDER BY i.created_at DESC
  LIMIT 1
)
WHERE incubation_id IS NULL;

-- If there are still chicks without incubation_id, create a default incubation
INSERT INTO public.incubations (user_id, name, pair_id, start_date, egg_count)
SELECT DISTINCT 
  c.user_id,
  'Geçmiş Kuluçka - ' || COALESCE(fb.name, 'Bilinmeyen') || ' x ' || COALESCE(mb.name, 'Bilinmeyen'),
  COALESCE(c.father_id, '') || '_' || COALESCE(c.mother_id, ''),
  COALESCE(c.hatch_date - INTERVAL '21 days', c.created_at),
  0
FROM public.chicks c
LEFT JOIN public.birds fb ON fb.id = c.father_id
LEFT JOIN public.birds mb ON mb.id = c.mother_id
WHERE c.incubation_id IS NULL;

-- Update remaining chicks to use the newly created incubations
UPDATE public.chicks 
SET incubation_id = (
  SELECT i.id FROM public.incubations i
  WHERE i.user_id = chicks.user_id
  ORDER BY i.created_at DESC
  LIMIT 1
)
WHERE incubation_id IS NULL;

-- Now make incubation_id NOT NULL
ALTER TABLE public.chicks 
ALTER COLUMN incubation_id SET NOT NULL;

-- 3. Add check constraints to ensure data consistency (only if not exists)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.check_constraints 
    WHERE constraint_name = 'eggs_must_have_clutch_or_incubation'
  ) THEN
    ALTER TABLE public.eggs 
    ADD CONSTRAINT eggs_must_have_clutch_or_incubation 
    CHECK (clutch_id IS NOT NULL OR incubation_id IS NOT NULL);
  END IF;
END $$;

-- 4. Create indexes for better performance (only if not exists)
CREATE INDEX IF NOT EXISTS idx_eggs_incubation_id ON public.eggs(incubation_id);
CREATE INDEX IF NOT EXISTS idx_chicks_incubation_id ON public.chicks(incubation_id);
CREATE INDEX IF NOT EXISTS idx_eggs_clutch_id ON public.eggs(clutch_id);

-- 5. Update triggers to maintain data consistency
CREATE OR REPLACE FUNCTION public.validate_egg_relationships()
RETURNS TRIGGER AS $$
BEGIN
  -- Ensure that egg has either clutch_id or incubation_id
  IF NEW.clutch_id IS NULL AND NEW.incubation_id IS NULL THEN
    RAISE EXCEPTION 'Yumurta bir kuluçka veya clutch ile ilişkilendirilmelidir';
  END IF;
  
  -- If incubation_id is provided, ensure it exists and belongs to the same user
  IF NEW.incubation_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.incubations 
      WHERE id = NEW.incubation_id AND user_id = NEW.user_id
    ) THEN
      RAISE EXCEPTION 'Geçersiz incubation_id veya yetki hatası: %', NEW.incubation_id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger (drop first to avoid conflicts)
DROP TRIGGER IF EXISTS validate_egg_relationships_trigger ON public.eggs;
CREATE TRIGGER validate_egg_relationships_trigger
  BEFORE INSERT OR UPDATE ON public.eggs
  FOR EACH ROW EXECUTE FUNCTION public.validate_egg_relationships();

-- 6. Create a function to ensure chicks have valid incubation relationships
CREATE OR REPLACE FUNCTION public.validate_chick_relationships()
RETURNS TRIGGER AS $$
BEGIN
  -- Ensure incubation_id exists and belongs to the same user
  IF NOT EXISTS (
    SELECT 1 FROM public.incubations 
    WHERE id = NEW.incubation_id AND user_id = NEW.user_id
  ) THEN
    RAISE EXCEPTION 'Geçersiz incubation_id veya yetki hatası: %', NEW.incubation_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger (drop first to avoid conflicts)
DROP TRIGGER IF EXISTS validate_chick_relationships_trigger ON public.chicks;
CREATE TRIGGER validate_chick_relationships_trigger
  BEFORE INSERT OR UPDATE ON public.chicks
  FOR EACH ROW EXECUTE FUNCTION public.validate_chick_relationships();