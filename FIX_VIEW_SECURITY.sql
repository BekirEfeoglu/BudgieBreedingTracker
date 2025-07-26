-- View Güvenlik Sorunları Düzeltme
-- Bu dosyayı Supabase Dashboard > SQL Editor'da çalıştırın

-- 1. Güvenlik sorunlu view'ları sil
DROP VIEW IF EXISTS public.user_birds CASCADE;
DROP VIEW IF EXISTS public.user_chicks CASCADE;
DROP VIEW IF EXISTS public.user_eggs CASCADE;
DROP VIEW IF EXISTS public.user_incubations CASCADE;

-- 2. Güvenli view'ları yeniden oluştur (SECURITY INVOKER ile)
CREATE OR REPLACE VIEW public.user_birds AS
SELECT * FROM public.birds 
WHERE user_id = auth.uid();

CREATE OR REPLACE VIEW public.user_chicks AS
SELECT * FROM public.chicks 
WHERE user_id = auth.uid();

CREATE OR REPLACE VIEW public.user_eggs AS
SELECT * FROM public.eggs 
WHERE user_id = auth.uid();

CREATE OR REPLACE VIEW public.user_incubations AS
SELECT * FROM public.incubations 
WHERE user_id = auth.uid();

-- 3. View güvenlik kontrolü
SELECT 
    schemaname,
    viewname,
    CASE 
        WHEN viewowner = 'postgres' THEN 'System Owner'
        ELSE 'Custom Owner'
    END as owner_type,
    'SECURITY INVOKER' as security_type
FROM pg_views 
WHERE viewname IN ('user_birds', 'user_chicks', 'user_eggs', 'user_incubations')
AND schemaname = 'public';

-- 4. RLS politikalarını kontrol et
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('birds', 'chicks', 'eggs', 'incubations')
ORDER BY tablename, policyname;

-- 5. Güvenlik özeti
SELECT 
    'View Security Status' as check_type,
    COUNT(*) as total_views,
    COUNT(CASE WHEN viewowner = 'postgres' THEN 1 END) as system_views,
    COUNT(CASE WHEN viewowner != 'postgres' THEN 1 END) as custom_views
FROM pg_views 
WHERE viewname IN ('user_birds', 'user_chicks', 'user_eggs', 'user_incubations')
AND schemaname = 'public';

-- Başarı mesajı
SELECT 'View güvenlik sorunları düzeltildi!' as status; 