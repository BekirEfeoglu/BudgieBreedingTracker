
-- Add incubation_id column to eggs table
ALTER TABLE public.eggs 
ADD COLUMN incubation_id UUID REFERENCES public.incubations(id);

-- Update existing eggs records to use incubation_id instead of clutch_id where possible
-- This step assumes that clutch_id might reference incubations table
UPDATE public.eggs 
SET incubation_id = clutch_id 
WHERE clutch_id IS NOT NULL 
AND EXISTS (SELECT 1 FROM public.incubations WHERE id = eggs.clutch_id);

-- Make incubation_id required after data migration
ALTER TABLE public.eggs 
ALTER COLUMN incubation_id SET NOT NULL;

-- Optionally, you can drop clutch_id column if it's no longer needed
-- ALTER TABLE public.eggs DROP COLUMN clutch_id;
