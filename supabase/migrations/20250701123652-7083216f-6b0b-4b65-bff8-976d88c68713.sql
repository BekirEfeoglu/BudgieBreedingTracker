
-- Update eggs table to include the new required fields
ALTER TABLE public.eggs 
ADD COLUMN IF NOT EXISTS weight_grams DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS estimated_hatch_date DATE;

-- Update the status enum to include the new status values
-- First check if we need to update the status constraint
DO $$
BEGIN
    -- Drop existing check constraint if it exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'eggs' AND constraint_type = 'CHECK' AND constraint_name LIKE '%status%'
    ) THEN
        ALTER TABLE public.eggs DROP CONSTRAINT IF EXISTS eggs_status_check;
    END IF;
    
    -- Add new check constraint with updated status values
    ALTER TABLE public.eggs 
    ADD CONSTRAINT eggs_status_check 
    CHECK (status IN ('laid', 'fertile', 'hatched', 'infertile', 'pending', 'cracked', 'damaged'));
END $$;

-- Update existing records to have proper estimated hatch dates if they don't have them
UPDATE public.eggs 
SET estimated_hatch_date = lay_date + INTERVAL '18 days'
WHERE estimated_hatch_date IS NULL;

-- Add index for better performance on clutch_id queries
CREATE INDEX IF NOT EXISTS idx_eggs_clutch_id ON public.eggs(clutch_id);
