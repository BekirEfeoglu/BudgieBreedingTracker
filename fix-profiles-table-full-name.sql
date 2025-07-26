-- PROFILES TABLOSUNA FULL_NAME KOLONU EKLEME
-- Bu dosyayı Supabase SQL Editor'de çalıştırın

-- 1. MEVCUT PROFILES TABLOSUNUN YAPISINI KONTROL ET
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

-- 2. FULL_NAME KOLONUNU EKLE (EĞER YOKSA)
DO $$ 
BEGIN
  -- full_name kolonu yoksa ekle
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'profiles' 
      AND column_name = 'full_name'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN full_name TEXT;
    RAISE NOTICE 'full_name kolonu eklendi';
  ELSE
    RAISE NOTICE 'full_name kolonu zaten mevcut';
  END IF;
END $$;

-- 3. MEVCUT FIRST_NAME VE LAST_NAME VERİLERİNİ FULL_NAME'E BİRLEŞTİR
UPDATE public.profiles 
SET full_name = CASE 
  WHEN first_name IS NOT NULL AND last_name IS NOT NULL 
    THEN first_name || ' ' || last_name
  WHEN first_name IS NOT NULL 
    THEN first_name
  WHEN last_name IS NOT NULL 
    THEN last_name
  ELSE NULL
END
WHERE full_name IS NULL;

-- 4. GÜNCELLENEN VERİLERİ KONTROL ET
SELECT 
  'GÜNCELLENEN PROFİLLER' as kontrol,
  id,
  first_name,
  last_name,
  full_name,
  updated_at
FROM public.profiles
ORDER BY updated_at DESC;

-- 5. YENİ TABLO YAPISINI KONTROL ET
SELECT 
  'YENİ PROFILES TABLO YAPISI' as kontrol,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'profiles'
ORDER BY ordinal_position; 