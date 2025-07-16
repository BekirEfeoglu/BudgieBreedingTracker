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

-- Create trigger to auto-initialize notification settings for new users
DROP TRIGGER IF EXISTS on_auth_user_created_notification_settings ON auth.users;
CREATE TRIGGER on_auth_user_created_notification_settings
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.initialize_user_notification_settings();

-- Fix real-time subscription issues by refreshing the publication
ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS public.birds;
ALTER PUBLICATION supabase_realtime ADD TABLE public.birds;

-- Ensure REPLICA IDENTITY is set for real-time updates
ALTER TABLE public.birds REPLICA IDENTITY FULL;
ALTER TABLE public.chicks REPLICA IDENTITY FULL;
ALTER TABLE public.eggs REPLICA IDENTITY FULL;
ALTER TABLE public.incubations REPLICA IDENTITY FULL;
ALTER TABLE public.clutches REPLICA IDENTITY FULL;

-- Initialize notification settings for existing user
INSERT INTO public.user_notification_settings (user_id)
SELECT id FROM auth.users
ON CONFLICT (user_id) DO NOTHING;