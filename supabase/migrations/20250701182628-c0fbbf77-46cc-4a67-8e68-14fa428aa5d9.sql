
-- Add missing is_deleted column to eggs table for soft deletion
ALTER TABLE public.eggs 
ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT false;

-- Add missing incubation_id column to chicks table  
ALTER TABLE public.chicks 
ADD COLUMN incubation_id UUID REFERENCES public.incubations(id);

-- Create index for better performance on soft-deleted eggs queries
CREATE INDEX IF NOT EXISTS idx_eggs_is_deleted ON public.eggs(is_deleted) WHERE is_deleted = false;

-- Create index for better performance on chicks incubation queries
CREATE INDEX IF NOT EXISTS idx_chicks_incubation_id ON public.chicks(incubation_id);
