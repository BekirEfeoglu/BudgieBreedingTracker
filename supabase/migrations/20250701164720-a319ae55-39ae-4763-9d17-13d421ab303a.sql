
-- Make clutch_id nullable since we're using incubation_id now
ALTER TABLE public.eggs 
ALTER COLUMN clutch_id DROP NOT NULL;

-- Set clutch_id to NULL for all existing records since we're using incubation_id
UPDATE public.eggs 
SET clutch_id = NULL 
WHERE incubation_id IS NOT NULL;
