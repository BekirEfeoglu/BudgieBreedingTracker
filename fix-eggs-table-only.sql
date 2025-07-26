-- Eggs tablosu - sadece eksik kolonları ekle
-- Publication zaten mevcut olduğu için sadece kolonları ekliyoruz

-- 1. is_deleted kolonunu ekle (eğer yoksa)
ALTER TABLE public.eggs ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;

-- 2. egg_number kolonunu ekle (eğer yoksa)
ALTER TABLE public.eggs ADD COLUMN IF NOT EXISTS egg_number INTEGER;

-- 3. İndeksler oluştur (eğer yoksa)
CREATE INDEX IF NOT EXISTS idx_eggs_incubation_id ON public.eggs(incubation_id);
CREATE INDEX IF NOT EXISTS idx_eggs_user_id ON public.eggs(user_id);
CREATE INDEX IF NOT EXISTS idx_eggs_is_deleted ON public.eggs(is_deleted);
CREATE INDEX IF NOT EXISTS idx_eggs_egg_number ON public.eggs(egg_number);

-- 4. Kontrol sorguları
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