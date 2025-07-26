-- Supabase şema önbelleğini yenile
-- Bu script Supabase'in şema önbelleğini temizler ve yeniler

-- Şema önbelleğini temizle
SELECT pg_notify('supabase_schema_cache_refresh', 'refresh');

-- Alternatif olarak, tabloyu yeniden yayınla
ALTER PUBLICATION supabase_realtime DROP TABLE public.incubations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.incubations;

-- Tablo yapısını kontrol et
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'incubations' 
AND table_schema = 'public'
ORDER BY ordinal_position;

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