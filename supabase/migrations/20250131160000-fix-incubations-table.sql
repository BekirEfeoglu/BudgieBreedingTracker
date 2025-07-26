-- Fix incubations table structure
-- Remove unused columns and ensure realtime is enabled

-- Drop the old table if it exists
DROP TABLE IF EXISTS public.incubations CASCADE;

-- Create incubations table with correct structure
CREATE TABLE public.incubations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  name TEXT NOT NULL,
  male_bird_id UUID,
  female_bird_id UUID,
  start_date DATE NOT NULL,
  enable_notifications BOOLEAN NOT NULL DEFAULT true,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own incubations" 
  ON public.incubations 
  FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own incubations" 
  ON public.incubations 
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own incubations" 
  ON public.incubations 
  FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own incubations" 
  ON public.incubations 
  FOR DELETE 
  USING (auth.uid() = user_id);

-- Add trigger for updated_at
CREATE TRIGGER update_incubations_updated_at
  BEFORE UPDATE ON public.incubations
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.incubations;

-- Create indexes for better performance
CREATE INDEX idx_incubations_user_id ON public.incubations(user_id);
CREATE INDEX idx_incubations_start_date ON public.incubations(start_date);
CREATE INDEX idx_incubations_male_bird_id ON public.incubations(male_bird_id);
CREATE INDEX idx_incubations_female_bird_id ON public.incubations(female_bird_id); 