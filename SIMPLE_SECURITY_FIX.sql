-- Basit Güvenlik Düzeltmesi
-- Bu dosyayı Supabase Dashboard > SQL Editor'da çalıştırın

-- 1. Mevcut fonksiyonu güvenli hale getir (silmeden)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

-- 2. Güvenlik için ek fonksiyonlar
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

-- 3. Güvenlik view'ları
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

-- 4. Güvenlik kontrolü
SELECT 
    'Function Security Check' as check_type,
    proname as function_name,
    CASE 
        WHEN prosecdef THEN 'SECURITY DEFINER' 
        ELSE 'SECURITY INVOKER' 
    END as security_level,
    CASE 
        WHEN proconfig IS NOT NULL AND array_length(proconfig, 1) > 0 THEN 'Search Path Set'
        ELSE 'Search Path Not Set'
    END as search_path_status
FROM pg_proc 
WHERE proname IN ('update_updated_at_column', 'gen_secure_uuid', 'gen_secure_timestamp')
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- Başarı mesajı
SELECT 'Güvenlik düzeltmesi tamamlandı!' as status; 