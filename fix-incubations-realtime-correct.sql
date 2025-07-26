-- incubations tablosunu Supabase realtime publication'ına ekle
-- PostgreSQL sözdizimi hatası düzeltildi

-- Önce tabloyu publication'dan çıkar (eğer varsa)
DO $$
BEGIN
    -- Tablo publication'da var mı kontrol et
    IF EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE tablename = 'incubations' 
        AND pubname = 'supabase_realtime'
    ) THEN
        ALTER PUBLICATION supabase_realtime DROP TABLE public.incubations;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Hata olursa sessizce devam et
        NULL;
END $$;

-- Tabloyu publication'a ekle
ALTER PUBLICATION supabase_realtime ADD TABLE public.incubations;

-- Tablo yapısını kontrol et
SELECT 
  schemaname,
  tablename,
  attname,
  atttypid::regtype as data_type,
  attnotnull as is_not_null,
  attnum as column_position
FROM pg_attribute 
JOIN pg_class ON pg_attribute.attrelid = pg_class.oid
JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
WHERE pg_namespace.nspname = 'public' 
AND pg_class.relname = 'incubations'
AND pg_attribute.attnum > 0
AND NOT pg_attribute.attisdropped
ORDER BY pg_attribute.attnum;

-- RLS politikalarını kontrol et
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
WHERE tablename = 'incubations';

-- Realtime durumunu kontrol et
SELECT 
  schemaname,
  tablename,
  pubname
FROM pg_publication_tables 
WHERE tablename = 'incubations';

-- Tablo var mı kontrol et
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'incubations'
) as table_exists; 