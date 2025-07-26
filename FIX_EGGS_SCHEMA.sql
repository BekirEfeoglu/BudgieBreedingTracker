-- Eggs tablosu schema düzeltme
-- start_date alanını ekle ve mevcut alanları kontrol et

-- 1. Mevcut eggs tablosu yapısını kontrol et
SELECT 'Mevcut eggs tablosu yapısı:' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'eggs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. start_date alanını ekle (eğer yoksa)
ALTER TABLE public.eggs ADD COLUMN IF NOT EXISTS start_date DATE;

-- 3. lay_date alanını kaldır (eğer varsa ve start_date ile çakışıyorsa)
-- ALTER TABLE public.eggs DROP COLUMN IF EXISTS lay_date;

-- 4. Güncellenmiş yapıyı kontrol et
SELECT 'Güncellenmiş eggs tablosu yapısı:' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'eggs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. İndeksleri kontrol et ve güncelle
CREATE INDEX IF NOT EXISTS idx_eggs_start_date ON public.eggs(start_date);
CREATE INDEX IF NOT EXISTS idx_eggs_incubation_id ON public.eggs(incubation_id);
CREATE INDEX IF NOT EXISTS idx_eggs_user_id ON public.eggs(user_id);
CREATE INDEX IF NOT EXISTS idx_eggs_egg_number ON public.eggs(egg_number);

-- 6. RLS politikalarını kontrol et
SELECT 'eggs tablosu RLS politikaları:' as info;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'eggs';

-- 7. Realtime durumunu kontrol et
SELECT 'eggs tablosu realtime durumu:' as info;
SELECT 
    schemaname,
    tablename,
    pubname
FROM pg_publication_tables 
WHERE tablename = 'eggs';

-- 8. Eğer realtime yoksa ekle
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.eggs; 