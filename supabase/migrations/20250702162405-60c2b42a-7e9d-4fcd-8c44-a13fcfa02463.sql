-- Enable realtime for birds and chicks tables
-- First enable replica identity for birds table
ALTER TABLE public.birds REPLICA IDENTITY FULL;

-- Enable replica identity for chicks table  
ALTER TABLE public.chicks REPLICA IDENTITY FULL;

-- Add the tables to the realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE public.birds;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chicks;