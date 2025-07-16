-- Supabase Realtime Sorunlarını Teşhis Et
-- Bu migration mevcut durumu analiz eder ve sorunları tespit eder

-- 1. TABLO YAPISI ANALİZİ
SELECT 
  '=== CHICKS TABLE STRUCTURE ===' as analysis_section;

SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns 
WHERE table_name = 'chicks' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. PUBLICATION DURUMU
SELECT 
  '=== PUBLICATION STATUS ===' as analysis_section;

SELECT 
  pubname,
  tablename,
  schemaname
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;

-- 3. TRIGGER DURUMU
SELECT 
  '=== TRIGGERS ===' as analysis_section;

SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'chicks' AND event_object_schema = 'public'
ORDER BY trigger_name;

-- 4. POLICY DURUMU
SELECT 
  '=== POLICIES ===' as analysis_section;

SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'chicks'
ORDER BY policyname;

-- 5. INDEX DURUMU
SELECT 
  '=== INDEXES ===' as analysis_section;

SELECT 
  indexname,
  indexdef
FROM pg_indexes 
WHERE tablename = 'chicks' AND schemaname = 'public'
ORDER BY indexname;

-- 6. FOREIGN KEY İLİŞKİLERİ
SELECT 
  '=== FOREIGN KEYS ===' as analysis_section;

SELECT 
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'chicks'
ORDER BY tc.constraint_name;

-- 7. TABLO İSTATİSTİKLERİ
SELECT 
  '=== TABLE STATISTICS ===' as analysis_section;

SELECT 
  schemaname,
  tablename,
  attname,
  n_distinct,
  correlation
FROM pg_stats 
WHERE tablename = 'chicks'
ORDER BY attname;

-- 8. REALTIME LOG ANALİZİ (eğer varsa)
SELECT 
  '=== REALTIME LOGS ===' as analysis_section;

-- Bu kısım Supabase'ın internal loglarına erişim gerektirir
-- Genellikle Supabase Dashboard'da görülebilir

-- 9. SAMPLE DATA ANALİZİ
SELECT 
  '=== SAMPLE DATA ===' as analysis_section;

SELECT 
  id,
  name,
  user_id,
  created_at,
  updated_at
FROM public.chicks 
LIMIT 5;

-- 10. PUBLICATION DETAYLARI
SELECT 
  '=== PUBLICATION DETAILS ===' as analysis_section;

SELECT 
  p.pubname,
  p.puballtables,
  p.pubinsert,
  p.pubupdate,
  p.pubdelete,
  p.pubtruncate
FROM pg_publication p
WHERE p.pubname = 'supabase_realtime'; 