-- PROFILES TABLOSU DÜZELTME
-- Bu dosyayı Supabase SQL Editor'de çalıştırın

-- 1. PROFILES TABLOSUNUN MEVCUT YAPISINI KONTROL ET
SELECT 
  'PROFILES TABLO YAPISI' as kontrol,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 2. PROFILES TABLOSUNU DÜZELT
-- Önce mevcut tabloyu sil (eğer varsa)
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Yeni profiles tablosunu oluştur
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

-- 3. USER_NOTIFICATION_SETTINGS TABLOSUNU DA KONTROL ET
SELECT 
  'USER_NOTIFICATION_SETTINGS TABLO YAPISI' as kontrol,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'user_notification_settings'
ORDER BY ordinal_position;

-- 4. USER_NOTIFICATION_SETTINGS TABLOSUNU DÜZELT
-- Önce mevcut tabloyu sil (eğer varsa)
DROP TABLE IF EXISTS public.user_notification_settings CASCADE;

-- Yeni user_notification_settings tablosunu oluştur
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

-- 6. TRIGGER'LARI OLUŞTUR (updated_at için)
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

-- 7. MEVCUT KULLANICILAR İÇİN PROFİL OLUŞTUR
DO $$
DECLARE
  current_user_id UUID;
  current_user_email TEXT;
BEGIN
  SELECT id, email INTO current_user_id, current_user_email
  FROM auth.users 
  ORDER BY created_at DESC 
  LIMIT 1;
  
  RAISE NOTICE 'Kullanıcı profili oluşturuluyor... ID: %, Email: %', current_user_id, current_user_email;
  
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
  
  RAISE NOTICE 'Kullanıcı profili ve bildirim ayarları oluşturuldu';
END $$;

-- 8. RLS'Yİ ETKİNLEŞTİR
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

-- 9. RLS POLİTİKALARINI OLUŞTUR
-- Önce tüm politikaları temizle
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can delete their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can manage their own profiles" ON public.profiles;

DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can view their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can insert their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can update their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can delete their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can manage their own notification settings" ON public.user_notification_settings;

-- Profiles için yeni politika oluştur
CREATE POLICY "Enable all access for authenticated users" 
ON public.profiles 
FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- User notification settings için yeni politika oluştur
CREATE POLICY "Enable all access for authenticated users" 
ON public.user_notification_settings 
FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- 10. SON DURUMU KONTROL ET
SELECT 
  'TABLO DURUMU' as kontrol,
  table_name,
  CASE 
    WHEN table_name IN ('profiles', 'user_notification_settings') 
    THEN '✅ MEVCUT'
    ELSE '❌ EKSİK'
  END as durum
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('profiles', 'user_notification_settings')
ORDER BY table_name;

-- 11. PROFİL VERİLERİNİ KONTROL ET
SELECT 
  'PROFİL VERİLERİ' as kontrol,
  p.id,
  p.email,
  p.first_name,
  p.last_name,
  p.created_at
FROM public.profiles p
ORDER BY p.created_at DESC;

-- 12. BİLDİRİM AYARLARINI KONTROL ET
SELECT 
  'BİLDİRİM AYARLARI' as kontrol,
  uns.user_id,
  uns.email_notifications,
  uns.push_notifications,
  uns.breeding_reminders,
  uns.health_reminders,
  uns.language
FROM public.user_notification_settings uns
ORDER BY uns.created_at DESC; 