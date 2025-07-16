-- Fix realtime subscription issues
-- Enable realtime for all main tables
ALTER TABLE public.birds REPLICA IDENTITY FULL;
ALTER TABLE public.chicks REPLICA IDENTITY FULL;
ALTER TABLE public.eggs REPLICA IDENTITY FULL;
ALTER TABLE public.incubations REPLICA IDENTITY FULL;
ALTER TABLE public.clutches REPLICA IDENTITY FULL;

-- Add tables to realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE public.birds;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chicks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.eggs;
ALTER PUBLICATION supabase_realtime ADD TABLE public.incubations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.clutches;