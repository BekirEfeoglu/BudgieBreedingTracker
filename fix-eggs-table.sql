-- eggs tablosu düzeltme
-- is_deleted kolonu ve diğer eksik alanları ekle

-- 1. is_deleted kolonunu ekle (eğer yoksa)
ALTER TABLE public.eggs ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;

-- 2. egg_number kolonunu ekle (eğer yoksa)
ALTER TABLE public.eggs ADD COLUMN IF NOT EXISTS egg_number INTEGER;

-- 3. Tabloyu publication'a ekle (eğer yoksa) - YORUM: Bu satırı atlayın, tablo zaten mevcut
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.eggs;

-- 4. İndeksler oluştur
CREATE INDEX IF NOT EXISTS idx_eggs_incubation_id ON public.eggs(incubation_id);
CREATE INDEX IF NOT EXISTS idx_eggs_user_id ON public.eggs(user_id);
CREATE INDEX IF NOT EXISTS idx_eggs_is_deleted ON public.eggs(is_deleted);
CREATE INDEX IF NOT EXISTS idx_eggs_egg_number ON public.eggs(egg_number);

-- 5. Kontrol sorguları
SELECT 'eggs tablosu yapısı:' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'eggs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'eggs tablosu realtime durumu:' as info;
SELECT 
    schemaname,
    tablename,
    pubname
FROM pg_publication_tables 
WHERE tablename = 'eggs';

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