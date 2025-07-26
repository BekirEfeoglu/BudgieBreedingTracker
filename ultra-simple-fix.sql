-- Ultra basit incubations düzeltme
-- Bu script sadece gerekli olanı yapar

-- 1. enable_notifications kolonunu ekle (eğer yoksa)
ALTER TABLE public.incubations ADD COLUMN IF NOT EXISTS enable_notifications BOOLEAN NOT NULL DEFAULT true;

-- 2. Tabloyu publication'a ekle (hata vermez)
ALTER PUBLICATION supabase_realtime ADD TABLE public.incubations;

-- 3. Kontrol
SELECT 'Tablo yapısı:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'incubations' 
AND table_schema = 'public'
ORDER BY ordinal_position; 