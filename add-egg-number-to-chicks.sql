-- Add egg_number column to chicks table
ALTER TABLE public.chicks 
ADD COLUMN IF NOT EXISTS egg_number INTEGER;

-- Add comment to explain the column
COMMENT ON COLUMN public.chicks.egg_number IS 'The number of the egg this chick hatched from';

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_chicks_egg_number ON public.chicks(egg_number) WHERE egg_number IS NOT NULL; 