-- RLS Performans Optimizasyonu Kontrolü
-- Bu dosya RLS politikalarının optimize edilip edilmediğini kontrol eder

-- 1. OPTIMIZE EDİLMEMİŞ POLİTİKALARI BUL
SELECT 
  'Non-Optimized Policies' as check_type,
  tablename,
  policyname,
  cmd as operation,
  CASE 
    WHEN qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%' THEN '❌ Needs Optimization'
    WHEN with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%' THEN '❌ Needs Optimization'
    ELSE '✅ Already Optimized'
  END as status
FROM pg_policies 
WHERE schemaname = 'public'
  AND (
    (qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%')
    OR (with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%')
  )
ORDER BY tablename, cmd;

-- 2. OPTIMIZE EDİLMİŞ POLİTİKALARI SAY
SELECT 
  'Optimization Summary' as check_type,
  COUNT(*) as total_policies,
  COUNT(CASE 
    WHEN qual LIKE '%(select auth.uid())%' OR with_check LIKE '%(select auth.uid())%' 
    THEN 1 END) as optimized_policies,
  COUNT(CASE 
    WHEN (qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%')
    OR (with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%')
    THEN 1 END) as non_optimized_policies,
  CASE 
    WHEN COUNT(CASE 
      WHEN (qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%')
      OR (with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%')
      THEN 1 END) = 0 THEN '✅ All Policies Optimized'
    ELSE '⚠️ Some Policies Need Optimization'
  END as overall_status
FROM pg_policies 
WHERE schemaname = 'public';

-- 3. TABLO BAZINDA OPTIMİZASYON DURUMU
SELECT 
  'Table Optimization Status' as check_type,
  tablename,
  COUNT(*) as total_policies,
  COUNT(CASE 
    WHEN qual LIKE '%(select auth.uid())%' OR with_check LIKE '%(select auth.uid())%' 
    THEN 1 END) as optimized_policies,
  COUNT(CASE 
    WHEN (qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%')
    OR (with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%')
    THEN 1 END) as non_optimized_policies,
  CASE 
    WHEN COUNT(CASE 
      WHEN (qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%')
      OR (with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%')
      THEN 1 END) = 0 THEN '✅ Fully Optimized'
    ELSE '⚠️ Needs Optimization'
  END as table_status
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- 4. PERFORMANS ETKİSİ ANALİZİ
WITH policy_analysis AS (
  SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
      WHEN qual LIKE '%(select auth.uid())%' OR with_check LIKE '%(select auth.uid())%' THEN 'Optimized'
      WHEN qual LIKE '%auth.uid()%' OR with_check LIKE '%auth.uid()%' THEN 'Non-Optimized'
      ELSE 'No Auth Function'
    END as optimization_type
  FROM pg_policies 
  WHERE schemaname = 'public'
)
SELECT 
  'Performance Impact Analysis' as check_type,
  optimization_type,
  COUNT(*) as policy_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage,
  CASE 
    WHEN optimization_type = 'Optimized' THEN '✅ Good Performance'
    WHEN optimization_type = 'Non-Optimized' THEN '⚠️ Performance Impact'
    ELSE 'ℹ️ No Impact'
  END as performance_impact
FROM policy_analysis
GROUP BY optimization_type
ORDER BY 
  CASE optimization_type
    WHEN 'Non-Optimized' THEN 1
    WHEN 'Optimized' THEN 2
    ELSE 3
  END;

-- 5. DETAYLI POLİTİKA İNCELEMESİ
SELECT 
  'Detailed Policy Analysis' as check_type,
  tablename,
  policyname,
  cmd as operation,
  CASE 
    WHEN qual LIKE '%(select auth.uid())%' THEN '✅ Optimized USING'
    WHEN qual LIKE '%auth.uid()%' THEN '❌ Non-Optimized USING'
    WHEN with_check LIKE '%(select auth.uid())%' THEN '✅ Optimized WITH CHECK'
    WHEN with_check LIKE '%auth.uid()%' THEN '❌ Non-Optimized WITH CHECK'
    ELSE 'ℹ️ No Auth Function'
  END as optimization_detail,
  CASE 
    WHEN qual LIKE '%(select auth.uid())%' OR with_check LIKE '%(select auth.uid())%' THEN 'Good'
    WHEN qual LIKE '%auth.uid()%' OR with_check LIKE '%auth.uid()%' THEN 'Poor'
    ELSE 'N/A'
  END as performance_rating
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY 
  CASE 
    WHEN qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%' THEN 1
    WHEN with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%' THEN 1
    ELSE 2
  END,
  tablename, cmd;

-- 6. ÖNERİLER
SELECT 
  'Recommendations' as section,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE schemaname = 'public'
        AND ((qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%')
        OR (with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%'))
    ) THEN '🔴 URGENT: Run OPTIMIZE_RLS_PERFORMANCE.sql to fix performance issues'
    ELSE '✅ All policies are optimized for performance'
  END as recommendation_1,
  '✅ Monitor query performance after optimization' as recommendation_2,
  '✅ Run this check regularly to ensure optimizations remain' as recommendation_3;

-- 7. PERFORMANS METRİKLERİ
SELECT 
  'Performance Metrics' as section,
  'Query execution time should improve by 20-50%' as metric_1,
  'Reduced CPU usage during RLS evaluation' as metric_2,
  'Better scalability for large datasets' as metric_3,
  'Improved concurrent user performance' as metric_4; 