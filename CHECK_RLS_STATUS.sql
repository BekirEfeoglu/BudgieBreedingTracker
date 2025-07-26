-- RLS Durum Kontrolü ve Güvenlik Doğrulaması
-- Bu dosya RLS'nin doğru şekilde etkinleştirildiğini ve politikaların oluşturulduğunu kontrol eder

-- 1. RLS DURUMU KONTROLÜ
SELECT 
  'RLS Status Check' as check_type,
  schemaname,
  tablename,
  rowsecurity as rls_enabled,
  CASE 
    WHEN rowsecurity THEN '✅ RLS Enabled'
    ELSE '❌ RLS Disabled - SECURITY RISK!'
  END as status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'profiles', 'birds', 'incubations', 'eggs', 'chicks', 
    'clutches', 'calendar', 'photos', 'backup_settings', 
    'backup_jobs', 'backup_history', 'feedback', 'notifications'
  )
ORDER BY tablename;

-- 2. POLICY SAYISI KONTROLÜ
SELECT 
  'Policy Count Check' as check_type,
  tablename,
  COUNT(*) as policy_count,
  CASE 
    WHEN COUNT(*) >= 3 THEN '✅ Sufficient Policies'
    WHEN COUNT(*) > 0 THEN '⚠️ Some Policies Missing'
    ELSE '❌ No Policies - SECURITY RISK!'
  END as status
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- 3. DETAYLI POLICY KONTROLÜ
SELECT 
  'Detailed Policy Check' as check_type,
  tablename,
  policyname,
  cmd as operation,
  CASE 
    WHEN cmd = 'SELECT' THEN '✅ Read Policy'
    WHEN cmd = 'INSERT' THEN '✅ Create Policy'
    WHEN cmd = 'UPDATE' THEN '✅ Update Policy'
    WHEN cmd = 'DELETE' THEN '✅ Delete Policy'
    ELSE '❓ Unknown Policy'
  END as policy_type,
  CASE 
    WHEN qual IS NOT NULL OR with_check IS NOT NULL THEN '✅ Policy Logic Present'
    ELSE '❌ No Policy Logic'
  END as logic_status
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, cmd;

-- 4. GÜVENLİK AÇIĞI KONTROLÜ
SELECT 
  'Security Vulnerability Check' as check_type,
  t.tablename,
  CASE 
    WHEN t.rowsecurity = false THEN '❌ CRITICAL: RLS Disabled'
    WHEN p.policy_count IS NULL THEN '❌ CRITICAL: No Policies'
    WHEN p.policy_count < 3 THEN '⚠️ WARNING: Insufficient Policies'
    ELSE '✅ SECURE: RLS Enabled with Policies'
  END as security_status,
  COALESCE(p.policy_count, 0) as policy_count
FROM pg_tables t
LEFT JOIN (
  SELECT 
    tablename,
    COUNT(*) as policy_count
  FROM pg_policies 
  WHERE schemaname = 'public'
  GROUP BY tablename
) p ON t.tablename = p.tablename
WHERE t.schemaname = 'public' 
  AND t.tablename IN (
    'profiles', 'birds', 'incubations', 'eggs', 'chicks', 
    'clutches', 'calendar', 'photos', 'backup_settings', 
    'backup_jobs', 'backup_history', 'feedback', 'notifications'
  )
ORDER BY 
  CASE 
    WHEN t.rowsecurity = false THEN 1
    WHEN p.policy_count IS NULL THEN 2
    WHEN p.policy_count < 3 THEN 3
    ELSE 4
  END,
  t.tablename;

-- 5. ÖZET RAPOR
WITH security_summary AS (
  SELECT 
    COUNT(*) as total_tables,
    COUNT(CASE WHEN rowsecurity = true THEN 1 END) as rls_enabled_tables,
    COUNT(CASE WHEN rowsecurity = false THEN 1 END) as rls_disabled_tables
  FROM pg_tables 
  WHERE schemaname = 'public' 
    AND tablename IN (
      'profiles', 'birds', 'incubations', 'eggs', 'chicks', 
      'clutches', 'calendar', 'photos', 'backup_settings', 
      'backup_jobs', 'backup_history', 'feedback', 'notifications'
    )
),
policy_summary AS (
  SELECT 
    COUNT(DISTINCT tablename) as tables_with_policies,
    COUNT(*) as total_policies
  FROM pg_policies 
  WHERE schemaname = 'public'
)
SELECT 
  'Security Summary Report' as report_type,
  s.total_tables,
  s.rls_enabled_tables,
  s.rls_disabled_tables,
  p.tables_with_policies,
  p.total_policies,
  CASE 
    WHEN s.rls_disabled_tables = 0 AND p.tables_with_policies = s.total_tables THEN '✅ ALL SECURE'
    WHEN s.rls_disabled_tables > 0 THEN '❌ CRITICAL SECURITY ISSUES'
    WHEN p.tables_with_policies < s.total_tables THEN '⚠️ SOME SECURITY ISSUES'
    ELSE '✅ MOSTLY SECURE'
  END as overall_status
FROM security_summary s
CROSS JOIN policy_summary p;

-- 6. ÖNERİLER
SELECT 
  'Recommendations' as section,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_tables 
      WHERE schemaname = 'public' 
        AND rowsecurity = false
        AND tablename IN (
          'profiles', 'birds', 'incubations', 'eggs', 'chicks', 
          'clutches', 'calendar', 'photos', 'backup_settings', 
          'backup_jobs', 'backup_history', 'feedback', 'notifications'
        )
    ) THEN '🔴 URGENT: Enable RLS on all tables using ENABLE_RLS_FIX.sql'
    ELSE '✅ RLS is enabled on all tables'
  END as recommendation_1,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_tables t
      WHERE t.schemaname = 'public'
        AND NOT EXISTS (
          SELECT 1 FROM pg_policies p 
          WHERE p.tablename = t.tablename 
            AND p.schemaname = 'public'
        )
        AND t.tablename IN (
          'profiles', 'birds', 'incubations', 'eggs', 'chicks', 
          'clutches', 'calendar', 'photos', 'backup_settings', 
          'backup_jobs', 'backup_history', 'feedback', 'notifications'
        )
    ) THEN '🔴 URGENT: Create policies for tables without policies'
    ELSE '✅ All tables have policies'
  END as recommendation_2,
  '✅ Run this check regularly to ensure security' as recommendation_3; 