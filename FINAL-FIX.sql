-- SON RLS DEVRE DIŞI BIRAKMA
-- Sadece kesinlikle mevcut olan tablolar için

-- 1. Temel tablolarda RLS'yi devre dışı bırak
ALTER TABLE public.birds DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_tokens DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_interactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 2. Bildirim ayarlarını mevcut kullanıcılar için oluştur
INSERT INTO public.user_notification_settings (user_id)
SELECT id FROM auth.users
ON CONFLICT (user_id) DO NOTHING;

-- 3. Durumu kontrol et
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings')
ORDER BY tablename; 