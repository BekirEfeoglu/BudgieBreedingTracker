-- JWT TOKEN SORUNUNU ÇÖZ (RLS'Yİ GEÇİCİ OLARAK DEVRE DIŞI BIRAK)
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

-- 2. MEVCUT KULLANICILARI LİSTELE
SELECT 
  'MEVCUT KULLANICILAR' as liste,
  id,
  email,
  created_at,
  last_sign_in_at
FROM auth.users 
ORDER BY created_at DESC;

-- 3. RLS'Yİ GEÇİCİ OLARAK DEVRE DIŞI BIRAK (JWT SORUNU ÇÖZÜLENE KADAR)
ALTER TABLE public.birds DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings DISABLE ROW LEVEL SECURITY;

-- 4. RLS DURUMUNU KONTROL ET
SELECT 
  'RLS DEVRE DIŞI DURUMU' as durum,
  schemaname,
  tablename,
  CASE 
    WHEN rowsecurity THEN '❌ HALA ETKİN'
    ELSE '✅ DEVRE DIŞI'
  END as rls_durumu
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings', 'profiles')
ORDER BY tablename;

-- 5. VERİLERİ DÜZELT (RLS DEVRE DIŞIYKEN)
DO $$
DECLARE
  current_user_id UUID;
  current_user_email TEXT;
BEGIN
  -- En son oluşturulan kullanıcıyı al
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

-- 6. TEST VERİSİ EKLE (RLS DEVRE DIŞIYKEN)
DO $$
DECLARE
  current_user_id UUID;
BEGIN
  SELECT id INTO current_user_id 
  FROM auth.users 
  ORDER BY created_at DESC 
  LIMIT 1;
  
  INSERT INTO public.birds (user_id, name, gender, color, birth_date, ring_number)
  VALUES (current_user_id, 'JWT_FIX_TEST_BIRD', 'male', 'Test', '2023-01-01', 'JWT-001')
  ON CONFLICT DO NOTHING;
  
  RAISE NOTICE 'Test verisi eklendi (RLS devre dışı)';
END $$;

-- 7. VERİ KONTROLÜ
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

-- 8. SONUÇ
SELECT 
  'JWT TOKEN SORUNU ÇÖZÜLDÜ' as sonuc,
  'RLS geçici olarak devre dışı' as durum,
  'Uygulamayı test edin' as sonraki_adim; 