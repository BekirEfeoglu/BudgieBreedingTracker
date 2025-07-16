-- Fix schema inconsistencies in eggs and chicks tables

-- 1. Fix eggs table: Make clutch_id nullable since we now have incubation_id
ALTER TABLE public.eggs 
ALTER COLUMN clutch_id DROP NOT NULL;

-- 2. Fix chicks table: Make incubation_id NOT NULL for data integrity
-- First, update any existing chicks without incubation_id to a default value
UPDATE public.chicks 
SET incubation_id = (
  SELECT id FROM public.incubations 
  WHERE (male_bird_id = chicks.father_id OR female_bird_id = chicks.mother_id)
  LIMIT 1
)
WHERE incubation_id IS NULL;

-- Then make incubation_id NOT NULL
ALTER TABLE public.chicks 
ALTER COLUMN incubation_id SET NOT NULL;

-- 3. Add foreign key constraints for better referential integrity
ALTER TABLE public.eggs 
ADD CONSTRAINT eggs_incubation_id_fkey 
FOREIGN KEY (incubation_id) REFERENCES public.incubations(id) ON DELETE CASCADE;

ALTER TABLE public.chicks 
ADD CONSTRAINT chicks_incubation_id_fkey 
FOREIGN KEY (incubation_id) REFERENCES public.incubations(id) ON DELETE CASCADE;

-- 4. Add check constraints to ensure data consistency
ALTER TABLE public.eggs 
ADD CONSTRAINT eggs_must_have_clutch_or_incubation 
CHECK (clutch_id IS NOT NULL OR incubation_id IS NOT NULL);

-- 5. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_eggs_incubation_id ON public.eggs(incubation_id);
CREATE INDEX IF NOT EXISTS idx_chicks_incubation_id ON public.chicks(incubation_id);

-- 6. Update triggers to maintain data consistency
CREATE OR REPLACE FUNCTION public.validate_egg_relationships()
RETURNS TRIGGER AS $$
BEGIN
  -- Ensure that egg has either clutch_id or incubation_id, but not necessarily both
  IF NEW.clutch_id IS NULL AND NEW.incubation_id IS NULL THEN
    RAISE EXCEPTION 'Egg must be associated with either a clutch or an incubation';
  END IF;
  
  -- If incubation_id is provided, ensure it exists
  IF NEW.incubation_id IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM public.incubations WHERE id = NEW.incubation_id) THEN
      RAISE EXCEPTION 'Invalid incubation_id: %', NEW.incubation_id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger
DROP TRIGGER IF EXISTS validate_egg_relationships_trigger ON public.eggs;
CREATE TRIGGER validate_egg_relationships_trigger
  BEFORE INSERT OR UPDATE ON public.eggs
  FOR EACH ROW EXECUTE FUNCTION public.validate_egg_relationships();

-- 7. Create a function to ensure chicks have valid incubation relationships
CREATE OR REPLACE FUNCTION public.validate_chick_relationships()
RETURNS TRIGGER AS $$
BEGIN
  -- Ensure incubation_id exists
  IF NOT EXISTS (SELECT 1 FROM public.incubations WHERE id = NEW.incubation_id) THEN
    RAISE EXCEPTION 'Invalid incubation_id for chick: %', NEW.incubation_id;
  END IF;
  
  -- Optional: Ensure parents match incubation parents
  IF NEW.father_id IS NOT NULL OR NEW.mother_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.incubations 
      WHERE id = NEW.incubation_id 
      AND (male_bird_id = NEW.father_id OR female_bird_id = NEW.mother_id)
    ) THEN
      RAISE WARNING 'Chick parents do not match incubation parents';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger
DROP TRIGGER IF EXISTS validate_chick_relationships_trigger ON public.chicks;
CREATE TRIGGER validate_chick_relationships_trigger
  BEFORE INSERT OR UPDATE ON public.chicks
  FOR EACH ROW EXECUTE FUNCTION public.validate_chick_relationships();