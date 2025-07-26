-- RLS'Yİ GÜVENLİ ŞEKİLDE ETKİNLEŞTİR (JWT TOKEN ÇALIŞIYOR)
-- Bu dosyayı Supabase SQL Editor'de çalıştırın

-- 1. MEVCUT AUTH DURUMUNU KONTROL ET
SELECT 
  'AUTH DURUMU KONTROLÜ' as kontrol,
  auth.uid() as current_user_id,
  auth.role() as current_role,
  CASE 
    WHEN auth.uid() IS NOT NULL THEN '✅ AUTH.UID() ÇALIŞIYOR'
    ELSE '❌ AUTH.UID() NULL - JWT TOKEN SORUNU'
  END as auth_uid_durumu;

-- 2. MEVCUT RLS DURUMUNU KONTROL ET
SELECT 
  'MEVCUT RLS DURUMU' as durum,
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

-- 3. MEVCUT POLİTİKALARI TEMİZLE
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

-- 4. RLS'Yİ ETKİNLEŞTİR
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

-- 5. GÜVENLİ RLS POLİTİKALARINI OLUŞTUR
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

-- 6. RLS ETKİN DURUMUNU KONTROL ET
SELECT 
  'RLS ETKİN DURUMU' as durum,
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

-- 7. OLUŞTURULAN POLİTİKALARI KONTROL ET
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

-- 8. TEST VERİSİ EKLE (RLS ETKİNYKEN)
DO $$
DECLARE
  current_user_id UUID;
BEGIN
  SELECT auth.uid() INTO current_user_id;
  
  IF current_user_id IS NOT NULL THEN
    INSERT INTO public.birds (user_id, name, gender, color, birth_date, ring_number)
    VALUES (current_user_id, 'RLS_SECURE_TEST_BIRD', 'female', 'Test', '2023-01-01', 'RLS-001')
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE 'Test verisi eklendi (RLS etkin): %', current_user_id;
  ELSE
    RAISE NOTICE 'AUTH.UID() NULL, test verisi eklenemedi';
  END IF;
END $$;

-- 9. VERİ KONTROLÜ
SELECT 
  'VERİ KONTROLÜ' as kontrol,
  'birds' as tablo,
  COUNT(*) as toplam_kayit,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as user_id_olan
FROM public.birds
UNION ALL
SELECT 
  'VERİ KONTROLÜ' as kontrol,
  'chicks' as tablo,
  COUNT(*) as toplam_kayit,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as user_id_olan
FROM public.chicks
UNION ALL
SELECT 
  'VERİ KONTROLÜ' as kontrol,
  'eggs' as tablo,
  COUNT(*) as toplam_kayit,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as user_id_olan
FROM public.eggs
UNION ALL
SELECT 
  'VERİ KONTROLÜ' as kontrol,
  'incubations' as tablo,
  COUNT(*) as toplam_kayit,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as user_id_olan
FROM public.incubations;

-- 10. SON AUTH TEST
SELECT 
  'SON AUTH TEST' as test,
  auth.uid() as current_user_id,
  auth.role() as current_role,
  CASE 
    WHEN auth.uid() IS NOT NULL THEN '✅ AUTH.UID() ÇALIŞIYOR'
    ELSE '❌ AUTH.UID() NULL - JWT TOKEN SORUNU'
  END as auth_uid_durumu;

-- 11. SONUÇ
SELECT 
  'RLS GÜVENLİ ŞEKİLDE ETKİNLEŞTİRİLDİ' as sonuc,
  'Kullanıcılar sadece kendi verilerine erişebilir' as güvenlik,
  'Uygulamayı test edin' as sonraki_adim; 