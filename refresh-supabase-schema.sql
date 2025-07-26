-- Supabase şema önbelleğini yenile
-- Bu script tüm şema önbelleğini temizler ve yeniler

-- 1. Şema önbelleğini temizle
SELECT pg_notify('supabase_schema_cache_refresh', 'refresh');

-- 2. Tüm tabloları publication'dan çıkar ve yeniden ekle
DO $$
DECLARE
    table_record RECORD;
BEGIN
    -- Tüm tabloları publication'dan çıkar
    FOR table_record IN 
        SELECT tablename 
        FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime'
    LOOP
        EXECUTE format('ALTER PUBLICATION supabase_realtime DROP TABLE public.%I', table_record.tablename);
    END LOOP;
    
    -- Tüm tabloları yeniden ekle
    FOR table_record IN 
        SELECT tablename 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
    LOOP
        BEGIN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', table_record.tablename);
        EXCEPTION
            WHEN OTHERS THEN
                -- Hata olursa sessizce devam et
                NULL;
        END;
    END LOOP;
END $$;

-- 3. incubations tablosunu özel olarak kontrol et
SELECT 'incubations tablosu durumu:' as info;
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'incubations'
) as table_exists;

-- 4. incubations tablosu yapısını kontrol et
SELECT 'incubations tablosu yapısı:' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'incubations' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. Realtime durumunu kontrol et
SELECT 'Realtime durumu:' as info;
SELECT 
    schemaname,
    tablename,
    pubname
FROM pg_publication_tables 
WHERE tablename = 'incubations';

-- 6. Eğer enable_notifications kolonu yoksa ekle
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