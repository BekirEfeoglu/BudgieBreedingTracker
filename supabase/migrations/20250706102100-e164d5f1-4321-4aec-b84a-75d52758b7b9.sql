-- Fix user_notification_settings table by ensuring proper user initialization
CREATE OR REPLACE FUNCTION public.initialize_user_notification_settings()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_notification_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure REPLICA IDENTITY is set for real-time updates
ALTER TABLE public.birds REPLICA IDENTITY FULL;
ALTER TABLE public.chicks REPLICA IDENTITY FULL;
ALTER TABLE public.eggs REPLICA IDENTITY FULL;
ALTER TABLE public.incubations REPLICA IDENTITY FULL;
ALTER TABLE public.clutches REPLICA IDENTITY FULL;

-- Add tables to realtime publication if not already added
ALTER PUBLICATION supabase_realtime ADD TABLE public.birds;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chicks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.eggs;
ALTER PUBLICATION supabase_realtime ADD TABLE public.incubations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.clutches;

-- Initialize notification settings for existing user
INSERT INTO public.user_notification_settings (user_id)
SELECT id FROM auth.users
ON CONFLICT (user_id) DO NOTHING;