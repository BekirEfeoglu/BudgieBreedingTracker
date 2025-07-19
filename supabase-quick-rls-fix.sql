-- HIZLI RLS FIX - TEST İÇİN
-- Bu dosya RLS'yi geçici olarak devre dışı bırakır

-- RLS'yi geçici olarak devre dışı bırak (test için)
ALTER TABLE public.birds DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Notification settings tablosu için de
ALTER TABLE public.user_notification_settings DISABLE ROW LEVEL SECURITY;

-- Backup settings tablosu için de
ALTER TABLE public.backup_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_jobs DISABLE ROW LEVEL SECURITY;

-- Clutches tablosu için de (eğer varsa)
ALTER TABLE public.clutches DISABLE ROW LEVEL SECURITY;

-- Test sonrası RLS'yi tekrar etkinleştirmek için:
-- ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY; 