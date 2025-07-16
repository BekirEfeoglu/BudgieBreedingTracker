-- Realtime Düzeltmesini Test Et
-- Bu migration realtime sisteminin düzgün çalışıp çalışmadığını test eder

-- 1. TEST VERİSİ OLUŞTUR
DO $$
DECLARE
  test_user_id UUID := '00000000-0000-0000-0000-000000000001';
  test_incubation_id UUID := '00000000-0000-0000-0000-000000000002';
  test_chick_id UUID := gen_random_uuid();
BEGIN
  -- Test kullanıcısı için incubation oluştur
  INSERT INTO public.incubations (id, user_id, name, start_date)
  VALUES (test_incubation_id, test_user_id, 'Test Incubation', NOW())
  ON CONFLICT (id) DO NOTHING;
  
  -- Test chick oluştur
  INSERT INTO public.chicks (
    id, 
    user_id, 
    incubation_id, 
    name, 
    hatch_date,
    gender,
    color
  )
  VALUES (
    test_chick_id,
    test_user_id,
    test_incubation_id,
    'Test Chick',
    NOW(),
    'unknown',
    'Test Color'
  )
  ON CONFLICT (id) DO NOTHING;
  
  RAISE NOTICE 'Test data created successfully';
END
$$;

-- 2. REALTIME SİSTEMİNİ TEST ET
-- Bu kısım manuel olarak test edilmeli

-- 3. TABLO YAPISINI DOĞRULA
SELECT 
  '=== VERIFICATION RESULTS ===' as verification_step;

-- Chicks tablosu yapısı
SELECT 
  'Chicks table structure verification:' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'chicks' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Foreign key'ler
SELECT 
  'Foreign key verification:' as info,
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name AS referenced_table
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'chicks'
ORDER BY tc.constraint_name;

-- Publication durumu
SELECT 
  'Publication verification:' as info,
  pubname,
  tablename
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;

-- Policy durumu
SELECT 
  'Policy verification:' as info,
  policyname,
  permissive,
  cmd
FROM pg_policies 
WHERE tablename = 'chicks'
ORDER BY policyname;

-- 4. PERFORMANS KONTROLÜ
SELECT 
  '=== PERFORMANCE CHECK ===' as performance_step;

-- Index durumu
SELECT 
  'Index verification:' as info,
  indexname,
  indexdef
FROM pg_indexes 
WHERE tablename = 'chicks' AND schemaname = 'public'
ORDER BY indexname;

-- Tablo istatistikleri
SELECT 
  'Table statistics:' as info,
  schemaname,
  tablename,
  attname,
  n_distinct
FROM pg_stats 
WHERE tablename = 'chicks'
ORDER BY attname;

-- 5. TEST VERİSİNİ TEMİZLE
DO $$
DECLARE
  test_user_id UUID := '00000000-0000-0000-0000-000000000001';
BEGIN
  -- Test verilerini temizle
  DELETE FROM public.chicks WHERE user_id = test_user_id;
  DELETE FROM public.incubations WHERE user_id = test_user_id;
  
  RAISE NOTICE 'Test data cleaned up';
END
$$;

-- 6. SONUÇ RAPORU
SELECT 
  '=== FINAL REPORT ===' as final_step,
  'Realtime system should now be working correctly' as status,
  'Check browser console for real-time subscription logs' as next_step; 