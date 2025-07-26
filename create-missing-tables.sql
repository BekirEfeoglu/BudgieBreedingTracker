-- EKSİK TABLOLARI KONTROL ET VE OLUŞTUR
-- Bu dosyayı Supabase SQL Editor'de çalıştırın

-- 1. MEVCUT TABLOLARI KONTROL ET
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

-- 2. PROFILES TABLOSUNU OLUŞTUR (EĞER YOKSA)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  first_name TEXT,
  last_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. USER_NOTIFICATION_SETTINGS TABLOSUNU OLUŞTUR (EĞER YOKSA)
CREATE TABLE IF NOT EXISTS public.user_notification_settings (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email_notifications BOOLEAN DEFAULT true,
  push_notifications BOOLEAN DEFAULT true,
  breeding_reminders BOOLEAN DEFAULT true,
  health_reminders BOOLEAN DEFAULT true,
  language TEXT DEFAULT 'tr',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. BIRDS TABLOSUNU KONTROL ET VE DÜZELT
DO $$
BEGIN
  -- user_id kolonu yoksa ekle
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'birds' 
      AND column_name = 'user_id'
  ) THEN
    ALTER TABLE public.birds ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
  
  -- user_id NOT NULL yap
  ALTER TABLE public.birds ALTER COLUMN user_id SET NOT NULL;
  
  RAISE NOTICE 'Birds tablosu kontrol edildi';
END $$;

-- 5. CHICKS TABLOSUNU KONTROL ET VE DÜZELT
DO $$
BEGIN
  -- user_id kolonu yoksa ekle
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'chicks' 
      AND column_name = 'user_id'
  ) THEN
    ALTER TABLE public.chicks ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
  
  -- user_id NOT NULL yap
  ALTER TABLE public.chicks ALTER COLUMN user_id SET NOT NULL;
  
  RAISE NOTICE 'Chicks tablosu kontrol edildi';
END $$;

-- 6. EGGS TABLOSUNU KONTROL ET VE DÜZELT
DO $$
BEGIN
  -- user_id kolonu yoksa ekle
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'eggs' 
      AND column_name = 'user_id'
  ) THEN
    ALTER TABLE public.eggs ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
  
  -- user_id NOT NULL yap
  ALTER TABLE public.eggs ALTER COLUMN user_id SET NOT NULL;
  
  RAISE NOTICE 'Eggs tablosu kontrol edildi';
END $$;

-- 7. INCUBATIONS TABLOSUNU KONTROL ET VE DÜZELT
DO $$
BEGIN
  -- user_id kolonu yoksa ekle
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'incubations' 
      AND column_name = 'user_id'
  ) THEN
    ALTER TABLE public.incubations ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
  
  -- user_id NOT NULL yap
  ALTER TABLE public.incubations ALTER COLUMN user_id SET NOT NULL;
  
  RAISE NOTICE 'Incubations tablosu kontrol edildi';
END $$;

-- 8. İNDEKSLERİ OLUŞTUR
CREATE INDEX IF NOT EXISTS idx_birds_user_id ON public.birds(user_id);
CREATE INDEX IF NOT EXISTS idx_chicks_user_id ON public.chicks(user_id);
CREATE INDEX IF NOT EXISTS idx_eggs_user_id ON public.eggs(user_id);
CREATE INDEX IF NOT EXISTS idx_incubations_user_id ON public.incubations(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_id ON public.profiles(id);
CREATE INDEX IF NOT EXISTS idx_user_notification_settings_user_id ON public.user_notification_settings(user_id);

-- 9. TRIGGER'LARI OLUŞTUR (updated_at için)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Birds için trigger
DROP TRIGGER IF EXISTS update_birds_updated_at ON public.birds;
CREATE TRIGGER update_birds_updated_at 
  BEFORE UPDATE ON public.birds 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Chicks için trigger
DROP TRIGGER IF EXISTS update_chicks_updated_at ON public.chicks;
CREATE TRIGGER update_chicks_updated_at 
  BEFORE UPDATE ON public.chicks 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Eggs için trigger
DROP TRIGGER IF EXISTS update_eggs_updated_at ON public.eggs;
CREATE TRIGGER update_eggs_updated_at 
  BEFORE UPDATE ON public.eggs 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Incubations için trigger
DROP TRIGGER IF EXISTS update_incubations_updated_at ON public.incubations;
CREATE TRIGGER update_incubations_updated_at 
  BEFORE UPDATE ON public.incubations 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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

-- 10. SON DURUMU KONTROL ET
SELECT 
  'TABLO DURUMU' as kontrol,
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

-- 11. KOLON DURUMUNU KONTROL ET
SELECT 
  'KOLON DURUMU' as kontrol,
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings', 'profiles')
  AND column_name = 'user_id'
ORDER BY table_name;

-- 12. İNDEKS DURUMUNU KONTROL ET
SELECT 
  'İNDEKS DURUMU' as kontrol,
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings', 'profiles')
  AND indexname LIKE '%user_id%'
ORDER BY tablename, indexname; 