-- DUPLICATE KUŞLARI TEMİZLE VE SORUNU ÇÖZ
-- Bu dosyayı Supabase SQL Editor'de çalıştırın

-- 1. MEVCUT DURUMU KONTROL ET
SELECT 
  'MEVCUT KUŞLAR' as durum,
  COUNT(*) as toplam_kuş,
  COUNT(DISTINCT name) as farklı_isim,
  COUNT(DISTINCT CONCAT(name, '_', gender)) as farklı_isim_cinsiyet
FROM public.birds;

-- 2. DUPLICATE KUŞLARI BUL
SELECT 
  'DUPLICATE KUŞLAR' as analiz,
  name,
  gender,
  COUNT(*) as sayı,
  STRING_AGG(id::text, ', ') as kuş_idleri
FROM public.birds 
GROUP BY name, gender 
HAVING COUNT(*) > 1
ORDER BY name, gender;

-- 3. DUPLICATE KUŞLARI TEMİZLE (en eski olanı tut)
WITH duplicates AS (
  SELECT 
    id,
    name,
    gender,
    created_at,
    ROW_NUMBER() OVER (
      PARTITION BY name, gender 
      ORDER BY created_at ASC
    ) as rn
  FROM public.birds
)
DELETE FROM public.birds 
WHERE id IN (
  SELECT id 
  FROM duplicates 
  WHERE rn > 1
);

-- 4. TEMİZLİK SONRASI DURUMU KONTROL ET
SELECT 
  'TEMİZLİK SONRASI' as durum,
  COUNT(*) as toplam_kuş,
  COUNT(DISTINCT name) as farklı_isim,
  COUNT(DISTINCT CONCAT(name, '_', gender)) as farklı_isim_cinsiyet
FROM public.birds;

-- 5. KALAN KUŞLARI LİSTELE
SELECT 
  'KALAN KUŞLAR' as liste,
  id,
  name,
  gender,
  created_at,
  updated_at
FROM public.birds 
ORDER BY created_at DESC;

-- 6. UNIQUE CONSTRAINT EKLE (gelecekte duplicate'leri önlemek için)
-- Önce mevcut constraint'leri kontrol et
SELECT 
  'MEVCUT CONSTRAINTLER' as kontrol,
  conname as constraint_name,
  contype as constraint_type
FROM pg_constraint 
WHERE conrelid = 'public.birds'::regclass;

-- 7. UNIQUE CONSTRAINT EKLE (eğer yoksa)
DO $$
BEGIN
  -- Unique constraint ekle (isim + cinsiyet kombinasyonu)
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'birds_name_gender_unique' 
    AND conrelid = 'public.birds'::regclass
  ) THEN
    ALTER TABLE public.birds 
    ADD CONSTRAINT birds_name_gender_unique 
    UNIQUE (name, gender);
    
    RAISE NOTICE 'Unique constraint eklendi: birds_name_gender_unique';
  ELSE
    RAISE NOTICE 'Unique constraint zaten mevcut: birds_name_gender_unique';
  END IF;
END $$;

-- 8. SONUÇ
SELECT 
  'DUPLICATE SORUNU ÇÖZÜLDÜ' as sonuc,
  'Unique constraint eklendi' as güvenlik,
  'Artık aynı isim ve cinsiyetli kuş eklenemez' as açıklama; 