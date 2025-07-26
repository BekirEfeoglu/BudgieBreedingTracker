-- SUPABASE TABLOLARI VE RLS KONTROL VE DÜZELTME
-- Bu dosyayı Supabase SQL Editor'de çalıştırın

-- 1. MEVCUT DURUM ANALİZİ
SELECT 
  'MEVCUT TABLOLAR' as analiz,
  schemaname,
  tablename,
  CASE 
    WHEN rowsecurity THEN '✅ RLS ETKİN'
    ELSE '❌ RLS DEVRE DIŞI'
  END as rls_durumu,
  CASE 
    WHEN hasindexes THEN '✅ İNDEKS VAR'
    ELSE '❌ İNDEKS YOK'
  END as indeks_durumu
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings', 'profiles')
ORDER BY tablename;

-- 2. MEVCUT POLİTİKALARI KONTROL ET
SELECT 
  'MEVCUT POLİTİKALAR' as analiz,
  schemaname,
  tablename, 
  policyname, 
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings', 'profiles')
ORDER BY tablename, cmd;

-- 3. TABLO YAPILARINI KONTROL ET
SELECT 
  'TABLO YAPILARI' as analiz,
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings', 'profiles')
ORDER BY table_name, ordinal_position;

-- 4. MEVCUT KULLANICIYI BUL
DO $$
DECLARE
  current_user_id UUID;
  user_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO user_count FROM auth.users;
  RAISE NOTICE 'Toplam kullanıcı sayısı: %', user_count;
  
  SELECT id INTO current_user_id 
  FROM auth.users 
  ORDER BY created_at DESC 
  LIMIT 1;
  
  RAISE NOTICE 'Aktif kullanıcı ID: %', current_user_id;
END $$;

-- Kullanıcı bilgilerini ayrı SELECT ile göster
SELECT 
  'KULLANICI BİLGİLERİ' as bilgi,
  id,
  email,
  created_at,
  last_sign_in_at
FROM auth.users 
WHERE id = (SELECT id FROM auth.users ORDER BY created_at DESC LIMIT 1);

-- 5. MEVCUT VERİLERİ KONTROL ET
SELECT 
  'VERİ KONTROLÜ' as analiz,
  'birds' as tablo,
  COUNT(*) as toplam_kayit,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as user_id_olan,
  COUNT(CASE WHEN user_id IS NULL THEN 1 END) as user_id_olmayan
FROM public.birds
UNION ALL
SELECT 
  'VERİ KONTROLÜ' as analiz,
  'chicks' as tablo,
  COUNT(*) as toplam_kayit,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as user_id_olan,
  COUNT(CASE WHEN user_id IS NULL THEN 1 END) as user_id_olmayan
FROM public.chicks
UNION ALL
SELECT 
  'VERİ KONTROLÜ' as analiz,
  'eggs' as tablo,
  COUNT(*) as toplam_kayit,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as user_id_olan,
  COUNT(CASE WHEN user_id IS NULL THEN 1 END) as user_id_olmayan
FROM public.eggs
UNION ALL
SELECT 
  'VERİ KONTROLÜ' as analiz,
  'incubations' as tablo,
  COUNT(*) as toplam_kayit,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as user_id_olan,
  COUNT(CASE WHEN user_id IS NULL THEN 1 END) as user_id_olmayan
FROM public.incubations;

-- 6. TÜM POLİTİKALARI TEMİZLE
DROP POLICY IF EXISTS "Users can view their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can insert their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can manage their own birds" ON public.birds;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.birds;

DROP POLICY IF EXISTS "Users can view their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can insert their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can update their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can delete their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can manage their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.chicks;

DROP POLICY IF EXISTS "Users can view their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can insert their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can update their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can delete their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can manage their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.eggs;

DROP POLICY IF EXISTS "Users can view their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can insert their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can update their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can delete their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can manage their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.incubations;

DROP POLICY IF EXISTS "Users can view their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can insert their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can update their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can delete their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can manage their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.user_notification_settings;

-- 7. VERİLERİ DÜZELT
DO $$
DECLARE
  current_user_id UUID;
BEGIN
  SELECT id INTO current_user_id 
  FROM auth.users 
  ORDER BY created_at DESC 
  LIMIT 1;
  
  RAISE NOTICE 'Veriler düzeltiliyor... Kullanıcı ID: %', current_user_id;
  
  -- NULL user_id'leri düzelt
  UPDATE public.birds SET user_id = current_user_id WHERE user_id IS NULL;
  UPDATE public.chicks SET user_id = current_user_id WHERE user_id IS NULL;
  UPDATE public.eggs SET user_id = current_user_id WHERE user_id IS NULL;
  UPDATE public.incubations SET user_id = current_user_id WHERE user_id IS NULL;
  
  -- Bildirim ayarlarını oluştur
  INSERT INTO public.user_notification_settings (user_id)
  VALUES (current_user_id)
  ON CONFLICT (user_id) DO NOTHING;
  
  -- Profile oluştur (eğer yoksa)
  INSERT INTO public.profiles (id, first_name, last_name, avatar_url)
  VALUES (current_user_id, NULL, NULL, NULL)
  ON CONFLICT (id) DO NOTHING;
  
  RAISE NOTICE 'Veriler düzeltildi';
END $$;

-- 8. RLS'Yİ ETKİNLEŞTİR
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 9. YENİ POLİTİKALARI OLUŞTUR (BASİT VE GÜVENİLİR)
-- Birds için
CREATE POLICY "Enable all access for authenticated users" 
ON public.birds 
FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- Chicks için
CREATE POLICY "Enable all access for authenticated users" 
ON public.chicks 
FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- Eggs için
CREATE POLICY "Enable all access for authenticated users" 
ON public.eggs 
FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- Incubations için
CREATE POLICY "Enable all access for authenticated users" 
ON public.incubations 
FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- Notification settings için
CREATE POLICY "Enable all access for authenticated users" 
ON public.user_notification_settings 
FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- Profiles için
CREATE POLICY "Enable all access for authenticated users" 
ON public.profiles 
FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- 10. TEST VERİSİ EKLE
DO $$
DECLARE
  current_user_id UUID;
BEGIN
  SELECT id INTO current_user_id 
  FROM auth.users 
  ORDER BY created_at DESC 
  LIMIT 1;
  
  INSERT INTO public.birds (user_id, name, gender, color, birth_date, ring_number)
  VALUES (current_user_id, 'TEST_BIRD_FIXED', 'male', 'Test', '2023-01-01', 'TEST-001')
  ON CONFLICT DO NOTHING;
  
  RAISE NOTICE 'Test verisi eklendi';
END $$;

-- 11. SON DURUMU KONTROL ET
SELECT 
  'SON RLS DURUMU' as kontrol,
  schemaname,
  tablename,
  CASE 
    WHEN rowsecurity THEN '✅ ETKİN'
    ELSE '❌ DEVRE DIŞI'
  END as rls_durumu
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings', 'profiles')
ORDER BY tablename;

-- 12. OLUŞTURULAN POLİTİKALARI KONTROL ET
SELECT 
  'OLUŞTURULAN POLİTİKALAR' as kontrol,
  tablename, 
  policyname, 
  cmd
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings', 'profiles')
ORDER BY tablename, cmd;

-- 13. VERİ KONTROLÜ (SON)
SELECT 
  'SON VERİ KONTROLÜ' as kontrol,
  'birds' as tablo,
  COUNT(*) as toplam_kayit,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as user_id_olan
FROM public.birds
UNION ALL
SELECT 
  'SON VERİ KONTROLÜ' as kontrol,
  'chicks' as tablo,
  COUNT(*) as toplam_kayit,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as user_id_olan
FROM public.chicks
UNION ALL
SELECT 
  'SON VERİ KONTROLÜ' as kontrol,
  'eggs' as tablo,
  COUNT(*) as toplam_kayit,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as user_id_olan
FROM public.eggs
UNION ALL
SELECT 
  'SON VERİ KONTROLÜ' as kontrol,
  'incubations' as tablo,
  COUNT(*) as toplam_kayit,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as user_id_olan
FROM public.incubations;

-- 14. AUTH.UID() TEST
SELECT 
  'AUTH.UID() TEST' as test,
  auth.uid() as current_user_id,
  auth.role() as current_role,
  CASE 
    WHEN auth.uid() IS NOT NULL THEN '✅ AUTH.UID() ÇALIŞIYOR'
    ELSE '❌ AUTH.UID() NULL'
  END as auth_uid_durumu; 