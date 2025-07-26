-- TÜM TABLOLARI VE RLS'Yİ SON KEZ DÜZELT
-- Bu dosyayı Supabase SQL Editor'de çalıştırın

-- 1. MEVCUT DURUMU KONTROL ET
SELECT 
  'MEVCUT TABLOLAR' as kontrol,
  table_name,
  CASE 
    WHEN table_name IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings', 'profiles') 
    THEN '✅ MEVCUT'
    ELSE '❌ EKSİK'
  END as durum
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings', 'profiles')
ORDER BY table_name;

-- 2. TÜM POLİTİKALARI TEMİZLE
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

-- 3. PROFILES TABLOSUNU DÜZELT
DROP TABLE IF EXISTS public.profiles CASCADE;

CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  first_name TEXT,
  last_name TEXT,
  avatar_url TEXT,
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. USER_NOTIFICATION_SETTINGS TABLOSUNU DÜZELT
DROP TABLE IF EXISTS public.user_notification_settings CASCADE;

CREATE TABLE public.user_notification_settings (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email_notifications BOOLEAN DEFAULT true,
  push_notifications BOOLEAN DEFAULT true,
  breeding_reminders BOOLEAN DEFAULT true,
  health_reminders BOOLEAN DEFAULT true,
  language TEXT DEFAULT 'tr',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. İNDEKSLERİ OLUŞTUR
CREATE INDEX IF NOT EXISTS idx_profiles_id ON public.profiles(id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_notification_settings_user_id ON public.user_notification_settings(user_id);

-- 6. TRIGGER'LARI OLUŞTUR
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Profiles için trigger
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON public.profiles 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- User notification settings için trigger
DROP TRIGGER IF EXISTS update_user_notification_settings_updated_at ON public.user_notification_settings;
CREATE TRIGGER update_user_notification_settings_updated_at 
  BEFORE UPDATE ON public.user_notification_settings 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. VERİLERİ DÜZELT
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

-- 8. RLS'Yİ ETKİNLEŞTİR
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

-- 9. YENİ POLİTİKALARI OLUŞTUR
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

-- Profiles için
CREATE POLICY "Enable all access for authenticated users" 
ON public.profiles 
FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- User notification settings için
CREATE POLICY "Enable all access for authenticated users" 
ON public.user_notification_settings 
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
  VALUES (current_user_id, 'FINAL_TEST_BIRD', 'male', 'Test', '2023-01-01', 'FINAL-001')
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

-- 14. PROFİL VE BİLDİRİM AYARLARINI KONTROL ET
SELECT 
  'PROFİL VE BİLDİRİM AYARLARI' as kontrol,
  p.id,
  p.email,
  uns.email_notifications,
  uns.language
FROM public.profiles p
LEFT JOIN public.user_notification_settings uns ON p.id = uns.user_id
ORDER BY p.created_at DESC; 