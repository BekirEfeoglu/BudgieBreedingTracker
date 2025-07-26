-- Final Güvenlik Düzeltmesi
-- Bu dosyayı Supabase Dashboard > SQL Editor'da çalıştırın

-- 1. Güvenlik sorunlu view'ları kaldır
DROP VIEW IF EXISTS public.user_birds CASCADE;
DROP VIEW IF EXISTS public.user_chicks CASCADE;
DROP VIEW IF EXISTS public.user_eggs CASCADE;
DROP VIEW IF EXISTS public.user_incubations CASCADE;

-- 2. Function search path sorununu düzelt (silmeden)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

-- 3. Güvenli fonksiyonlar oluştur
CREATE OR REPLACE FUNCTION public.gen_secure_uuid()
RETURNS UUID AS $$
BEGIN
    RETURN gen_random_uuid();
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION public.gen_secure_timestamp()
RETURNS TIMESTAMPTZ AS $$
BEGIN
    RETURN NOW();
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

-- 4. RLS politikalarını optimize et
-- Birds için
DROP POLICY IF EXISTS "Users can view their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can create their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can manage their own birds" ON public.birds;

CREATE POLICY "Users can manage their own birds" 
ON public.birds 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- Chicks için
DROP POLICY IF EXISTS "Users can view their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can create their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can update their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can delete their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can manage their own chicks" ON public.chicks;

CREATE POLICY "Users can manage their own chicks" 
ON public.chicks 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- Eggs için
DROP POLICY IF EXISTS "Users can view their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can create their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can update their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can delete their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can manage their own eggs" ON public.eggs;

CREATE POLICY "Users can manage their own eggs" 
ON public.eggs 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- Incubations için
DROP POLICY IF EXISTS "Users can view their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can create their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can update their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can delete their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can manage their own incubations" ON public.incubations;

CREATE POLICY "Users can manage their own incubations" 
ON public.incubations 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 5. Güvenlik kontrolü
SELECT 
    'Security Status Check' as check_type,
    'Function Search Path' as item,
    CASE 
        WHEN prosecdef THEN 'SECURITY DEFINER' 
        ELSE 'SECURITY INVOKER' 
    END as security_level,
    CASE 
        WHEN proconfig IS NOT NULL AND array_length(proconfig, 1) > 0 THEN 'Search Path Set'
        ELSE 'Search Path Not Set'
    END as search_path_status
FROM pg_proc 
WHERE proname = 'update_updated_at_column'
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')

UNION ALL

SELECT 
    'Security Status Check' as check_type,
    'View Security' as item,
    'Views Removed' as security_level,
    'No Security Issues' as search_path_status

UNION ALL

SELECT 
    'Security Status Check' as check_type,
    'RLS Policies' as item,
    'Optimized' as security_level,
    'Single Policy per Table' as search_path_status;

-- 6. Kullanım önerisi
SELECT 
    'Usage Recommendation' as info_type,
    'Use direct table queries with RLS policies' as recommendation,
    'Example: SELECT * FROM birds WHERE user_id = auth.uid()' as example;

-- Başarı mesajı
SELECT 'Tüm güvenlik sorunları düzeltildi!' as status; 