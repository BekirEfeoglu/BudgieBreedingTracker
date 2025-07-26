-- Basit incubations tablosu düzeltme (PostgreSQL sözdizimi düzeltildi)
-- Bu script sadece realtime'i düzeltir, tabloyu silmez

-- 1. Önce tabloyu publication'dan çıkar (hata vermez)
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime DROP TABLE public.incubations;
EXCEPTION
    WHEN OTHERS THEN
        -- Tablo zaten yoksa hata verme
        NULL;
END $$;

-- 2. Tabloyu publication'a ekle
ALTER PUBLICATION supabase_realtime ADD TABLE public.incubations;

-- 3. enable_notifications kolonunu ekle (eğer yoksa)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'incubations' 
        AND table_schema = 'public' 
        AND column_name = 'enable_notifications'
    ) THEN
        ALTER TABLE public.incubations ADD COLUMN enable_notifications BOOLEAN NOT NULL DEFAULT true;
        RAISE NOTICE 'enable_notifications kolonu eklendi';
    ELSE
        RAISE NOTICE 'enable_notifications kolonu zaten mevcut';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Hata: %', SQLERRM;
END $$;

-- 4. Kontrol sorguları
SELECT 'Tablo durumu:' as info;
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'incubations'
) as table_exists;

SELECT 'Realtime durumu:' as info;
SELECT 
    schemaname,
    tablename,
    pubname
FROM pg_publication_tables 
WHERE tablename = 'incubations';

SELECT 'Tablo yapısı:' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'incubations' 
AND table_schema = 'public'
ORDER BY ordinal_position; 