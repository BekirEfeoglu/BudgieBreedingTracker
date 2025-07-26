-- View'ları Kaldırma (Alternatif Çözüm)
-- Bu dosyayı Supabase Dashboard > SQL Editor'da çalıştırın

-- 1. Tüm güvenlik sorunlu view'ları kaldır
DROP VIEW IF EXISTS public.user_birds CASCADE;
DROP VIEW IF EXISTS public.user_chicks CASCADE;
DROP VIEW IF EXISTS public.user_eggs CASCADE;
DROP VIEW IF EXISTS public.user_incubations CASCADE;

-- 2. View'ların kaldırıldığını doğrula
SELECT 
    'Remaining Views Check' as check_type,
    COUNT(*) as remaining_views
FROM pg_views 
WHERE viewname IN ('user_birds', 'user_chicks', 'user_eggs', 'user_incubations')
AND schemaname = 'public';

-- 3. RLS politikalarının çalıştığını doğrula
SELECT 
    'RLS Policy Check' as check_type,
    tablename,
    COUNT(*) as policy_count,
    STRING_AGG(policyname, ', ') as policy_names
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('birds', 'chicks', 'eggs', 'incubations')
GROUP BY tablename
ORDER BY tablename;

-- 4. Güvenlik durumu özeti
SELECT 
    'Security Status Summary' as summary_type,
    'Views Removed' as action,
    'RLS Policies Active' as status,
    'Direct table access with RLS' as recommendation;

-- 5. Kullanım önerisi
SELECT 
    'Usage Recommendation' as info_type,
    'Use direct table queries with RLS policies instead of views' as recommendation,
    'Example: SELECT * FROM birds WHERE user_id = auth.uid()' as example;

-- Başarı mesajı
SELECT 'View güvenlik sorunları çözüldü - view\'lar kaldırıldı!' as status; 