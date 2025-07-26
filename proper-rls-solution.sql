-- RLS'Yİ DOĞRU ŞEKİLDE YAPILANDIR (DEVREDİŞI BIRAKMADAN)
-- Bu dosyayı Supabase SQL Editor'de çalıştırın

-- 1. MEVCUT DURUMU ANALİZ ET
SELECT 
  'MEVCUT RLS DURUMU' as analiz,
  schemaname,
  tablename,
  CASE 
    WHEN rowsecurity THEN '✅ RLS ETKİN'
    ELSE '❌ RLS DEVRE DIŞI'
  END as rls_durumu
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

-- 3. AUTH.UID() FONKSİYONUNU TEST ET
SELECT 
  'AUTH.UID() TEST' as test,
  auth.uid() as current_user_id,
  auth.role() as current_role,
  CASE 
    WHEN auth.uid() IS NOT NULL THEN '✅ AUTH.UID() ÇALIŞIYOR'
    ELSE '❌ AUTH.UID() NULL - JWT TOKEN SORUNU'
  END as auth_uid_durumu;

-- 4. MEVCUT KULLANICIYI BUL
DO $$
DECLARE
  current_user_id UUID;
  current_user_email TEXT;
BEGIN
  SELECT id, email INTO current_user_id, current_user_email
  FROM auth.users 
  ORDER BY created_at DESC 
  LIMIT 1;
  
  RAISE NOTICE 'Aktif kullanıcı: ID=%, Email=%', current_user_id, current_user_email;
END $$;

-- 5. TÜM POLİTİKALARI TEMİZLE
-- Birds için
DROP POLICY IF EXISTS "Users can view their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can insert their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can manage their own birds" ON public.birds;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.birds;

-- Chicks için
DROP POLICY IF EXISTS "Users can view their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can insert their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can update their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can delete their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can manage their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.chicks;

-- Eggs için
DROP POLICY IF EXISTS "Users can view their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can insert their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can update their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can delete their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can manage their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.eggs;

-- Incubations için
DROP POLICY IF EXISTS "Users can view their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can insert their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can update their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can delete their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can manage their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.incubations;

-- Profiles için
DROP POLICY IF EXISTS "Users can view their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can delete their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can manage their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.profiles;

-- User notification settings için
DROP POLICY IF EXISTS "Users can view their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can insert their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can update their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can delete their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can manage their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.user_notification_settings;

-- 6. RLS'Yİ ETKİNLEŞTİR (ZATEN ETKİN OLMALI)
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

-- 7. DOĞRU RLS POLİTİKALARINI OLUŞTUR
-- Birds için - auth.uid() ile
CREATE POLICY "Users can view their own birds" 
ON public.birds 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own birds" 
ON public.birds 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own birds" 
ON public.birds 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own birds" 
ON public.birds 
FOR DELETE 
USING (auth.uid() = user_id);

-- Chicks için - auth.uid() ile
CREATE POLICY "Users can view their own chicks" 
ON public.chicks 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own chicks" 
ON public.chicks 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own chicks" 
ON public.chicks 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own chicks" 
ON public.chicks 
FOR DELETE 
USING (auth.uid() = user_id);

-- Eggs için - auth.uid() ile
CREATE POLICY "Users can view their own eggs" 
ON public.eggs 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own eggs" 
ON public.eggs 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own eggs" 
ON public.eggs 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own eggs" 
ON public.eggs 
FOR DELETE 
USING (auth.uid() = user_id);

-- Incubations için - auth.uid() ile
CREATE POLICY "Users can view their own incubations" 
ON public.incubations 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own incubations" 
ON public.incubations 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own incubations" 
ON public.incubations 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own incubations" 
ON public.incubations 
FOR DELETE 
USING (auth.uid() = user_id);

-- Profiles için - auth.uid() ile
CREATE POLICY "Users can view their own profiles" 
ON public.profiles 
FOR SELECT 
USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profiles" 
ON public.profiles 
FOR INSERT 
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profiles" 
ON public.profiles 
FOR UPDATE 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete their own profiles" 
ON public.profiles 
FOR DELETE 
USING (auth.uid() = id);

-- User notification settings için - auth.uid() ile
CREATE POLICY "Users can view their own notification settings" 
ON public.user_notification_settings 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notification settings" 
ON public.user_notification_settings 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notification settings" 
ON public.user_notification_settings 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notification settings" 
ON public.user_notification_settings 
FOR DELETE 
USING (auth.uid() = user_id);

-- 8. VERİLERİ DÜZELT
DO $$
DECLARE
  current_user_id UUID;
  current_user_email TEXT;
BEGIN
  SELECT id, email INTO current_user_id, current_user_email
  FROM auth.users 
  ORDER BY created_at DESC 
  LIMIT 1;
  
  RAISE NOTICE 'Veriler düzeltiliyor... Kullanıcı ID: %, Email: %', current_user_id, current_user_email;
  
  -- NULL user_id'leri düzelt
  UPDATE public.birds SET user_id = current_user_id WHERE user_id IS NULL;
  UPDATE public.chicks SET user_id = current_user_id WHERE user_id IS NULL;
  UPDATE public.eggs SET user_id = current_user_id WHERE user_id IS NULL;
  UPDATE public.incubations SET user_id = current_user_id WHERE user_id IS NULL;
  
  -- Profile oluştur
  INSERT INTO public.profiles (id, email, first_name, last_name, avatar_url)
  VALUES (current_user_id, current_user_email, NULL, NULL, NULL)
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = NOW();
  
  -- Bildirim ayarlarını oluştur
  INSERT INTO public.user_notification_settings (user_id)
  VALUES (current_user_id)
  ON CONFLICT (user_id) DO NOTHING;
  
  RAISE NOTICE 'Veriler düzeltildi';
END $$;

-- 9. TEST VERİSİ EKLE (RLS ETKİNYKEN)
DO $$
DECLARE
  current_user_id UUID;
BEGIN
  SELECT id INTO current_user_id 
  FROM auth.users 
  ORDER BY created_at DESC 
  LIMIT 1;
  
  INSERT INTO public.birds (user_id, name, gender, color, birth_date, ring_number)
  VALUES (current_user_id, 'PROPER_RLS_TEST_BIRD', 'male', 'Test', '2023-01-01', 'PROPER-001')
  ON CONFLICT DO NOTHING;
  
  RAISE NOTICE 'Test verisi eklendi (RLS etkin)';
END $$;

-- 10. SON DURUMU KONTROL ET
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

-- 11. OLUŞTURULAN POLİTİKALARI KONTROL ET
SELECT 
  'OLUŞTURULAN POLİTİKALAR' as kontrol,
  tablename, 
  policyname, 
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings', 'profiles')
ORDER BY tablename, cmd;

-- 12. VERİ KONTROLÜ (SON)
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

-- 13. AUTH.UID() SON TEST
SELECT 
  'AUTH.UID() SON TEST' as test,
  auth.uid() as current_user_id,
  auth.role() as current_role,
  CASE 
    WHEN auth.uid() IS NOT NULL THEN '✅ AUTH.UID() ÇALIŞIYOR'
    ELSE '❌ AUTH.UID() NULL - JWT TOKEN SORUNU'
  END as auth_uid_durumu; 