-- Initialize notification settings for existing user
INSERT INTO public.user_notification_settings (user_id)
SELECT id FROM auth.users
ON CONFLICT (user_id) DO NOTHING;

-- Ensure REPLICA IDENTITY is set for real-time updates (this fixes subscription errors)
ALTER TABLE public.birds REPLICA IDENTITY FULL;
ALTER TABLE public.chicks REPLICA IDENTITY FULL;
ALTER TABLE public.eggs REPLICA IDENTITY FULL;
ALTER TABLE public.incubations REPLICA IDENTITY FULL;
ALTER TABLE public.clutches REPLICA IDENTITY FULL;