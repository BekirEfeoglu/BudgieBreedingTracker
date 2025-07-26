-- Güvenlik Uyarılarını Düzeltme
-- Bu migration dosyası Supabase Linter'ın tespit ettiği güvenlik sorunlarını düzeltir

-- 1. Function Search Path Mutable Sorunu Düzeltme
-- handle_updated_at fonksiyonunu güvenli hale getir

-- Önce mevcut fonksiyonu sil
DROP FUNCTION IF EXISTS public.handle_updated_at() CASCADE;

-- Güvenli versiyonunu oluştur
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

-- Tüm trigger'ları yeniden oluştur
-- Birds tablosu için
DROP TRIGGER IF EXISTS handle_birds_updated_at ON public.birds;
CREATE TRIGGER handle_birds_updated_at
    BEFORE UPDATE ON public.birds
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Chicks tablosu için
DROP TRIGGER IF EXISTS handle_chicks_updated_at ON public.chicks;
CREATE TRIGGER handle_chicks_updated_at
    BEFORE UPDATE ON public.chicks
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Eggs tablosu için
DROP TRIGGER IF EXISTS handle_eggs_updated_at ON public.eggs;
CREATE TRIGGER handle_eggs_updated_at
    BEFORE UPDATE ON public.eggs
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Incubations tablosu için
DROP TRIGGER IF EXISTS handle_incubations_updated_at ON public.incubations;
CREATE TRIGGER handle_incubations_updated_at
    BEFORE UPDATE ON public.incubations
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Profiles tablosu için
DROP TRIGGER IF EXISTS handle_profiles_updated_at ON public.profiles;
CREATE TRIGGER handle_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Clutches tablosu için
DROP TRIGGER IF EXISTS handle_clutches_updated_at ON public.clutches;
CREATE TRIGGER handle_clutches_updated_at
    BEFORE UPDATE ON public.clutches
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Calendar tablosu için
DROP TRIGGER IF EXISTS handle_calendar_updated_at ON public.calendar;
CREATE TRIGGER handle_calendar_updated_at
    BEFORE UPDATE ON public.calendar
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Backup settings tablosu için
DROP TRIGGER IF EXISTS handle_backup_settings_updated_at ON public.backup_settings;
CREATE TRIGGER handle_backup_settings_updated_at
    BEFORE UPDATE ON public.backup_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Feedback tablosu için
DROP TRIGGER IF EXISTS handle_feedback_updated_at ON public.feedback;
CREATE TRIGGER handle_feedback_updated_at
    BEFORE UPDATE ON public.feedback
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- User notification settings tablosu için
DROP TRIGGER IF EXISTS handle_user_notification_settings_updated_at ON public.user_notification_settings;
CREATE TRIGGER handle_user_notification_settings_updated_at
    BEFORE UPDATE ON public.user_notification_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- User notification tokens tablosu için
DROP TRIGGER IF EXISTS handle_user_notification_tokens_updated_at ON public.user_notification_tokens;
CREATE TRIGGER handle_user_notification_tokens_updated_at
    BEFORE UPDATE ON public.user_notification_tokens
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Notification interactions tablosu için
DROP TRIGGER IF EXISTS handle_notification_interactions_updated_at ON public.notification_interactions;
CREATE TRIGGER handle_notification_interactions_updated_at
    BEFORE UPDATE ON public.notification_interactions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Temperature sensors tablosu için
DROP TRIGGER IF EXISTS handle_temperature_sensors_updated_at ON public.temperature_sensors;
CREATE TRIGGER handle_temperature_sensors_updated_at
    BEFORE UPDATE ON public.temperature_sensors
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Temperature readings tablosu için
DROP TRIGGER IF EXISTS handle_temperature_readings_updated_at ON public.temperature_readings;
CREATE TRIGGER handle_temperature_readings_updated_at
    BEFORE UPDATE ON public.temperature_readings
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Todos tablosu için
DROP TRIGGER IF EXISTS handle_todos_updated_at ON public.todos;
CREATE TRIGGER handle_todos_updated_at
    BEFORE UPDATE ON public.todos
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Subscription plans tablosu için
DROP TRIGGER IF EXISTS handle_subscription_plans_updated_at ON public.subscription_plans;
CREATE TRIGGER handle_subscription_plans_updated_at
    BEFORE UPDATE ON public.subscription_plans
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- User subscriptions tablosu için
DROP TRIGGER IF EXISTS handle_user_subscriptions_updated_at ON public.user_subscriptions;
CREATE TRIGGER handle_user_subscriptions_updated_at
    BEFORE UPDATE ON public.user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Subscription usage tablosu için
DROP TRIGGER IF EXISTS handle_subscription_usage_updated_at ON public.subscription_usage;
CREATE TRIGGER handle_subscription_usage_updated_at
    BEFORE UPDATE ON public.subscription_usage
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Subscription events tablosu için
DROP TRIGGER IF EXISTS handle_subscription_events_updated_at ON public.subscription_events;
CREATE TRIGGER handle_subscription_events_updated_at
    BEFORE UPDATE ON public.subscription_events
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 2. Diğer güvenli fonksiyonları da düzelt
-- is_user_premium fonksiyonu
DROP FUNCTION IF EXISTS public.is_user_premium(uuid);
CREATE OR REPLACE FUNCTION public.is_user_premium(user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    is_premium boolean := false;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.user_subscriptions us
        JOIN public.subscription_plans sp ON us.plan_id = sp.id
        WHERE us.user_id = $1 
        AND us.status = 'active'
        AND us.end_date > NOW()
        AND sp.name != 'free'
    ) INTO is_premium;
    
    RETURN is_premium;
EXCEPTION
    WHEN undefined_table THEN
        RETURN false;
END;
$$;

-- check_feature_limit fonksiyonu
DROP FUNCTION IF EXISTS public.check_feature_limit(uuid, text, integer);
CREATE OR REPLACE FUNCTION public.check_feature_limit(user_id uuid, feature_name text, current_count integer)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_limit integer;
    is_premium boolean;
BEGIN
    -- Kullanıcının premium durumunu kontrol et
    SELECT public.is_user_premium($1) INTO is_premium;
    
    -- Limitleri belirle
    CASE 
        WHEN is_premium THEN
            -- Premium kullanıcılar için yüksek limitler
            CASE $2
                WHEN 'birds' THEN user_limit := 100;
                WHEN 'incubations' THEN user_limit := 20;
                WHEN 'eggs' THEN user_limit := 200;
                WHEN 'chicks' THEN user_limit := 100;
                WHEN 'photos' THEN user_limit := 1000;
                WHEN 'notifications' THEN user_limit := 100;
                ELSE user_limit := 999;
            END CASE;
        ELSE
            -- Ücretsiz kullanıcılar için düşük limitler
            CASE $2
                WHEN 'birds' THEN user_limit := 3;
                WHEN 'incubations' THEN user_limit := 1;
                WHEN 'eggs' THEN user_limit := 6;
                WHEN 'chicks' THEN user_limit := 3;
                WHEN 'photos' THEN user_limit := 10;
                WHEN 'notifications' THEN user_limit := 5;
                ELSE user_limit := 10;
            END CASE;
    END CASE;
    
    RETURN $3 < user_limit;
EXCEPTION
    WHEN undefined_table THEN
        RETURN true; -- Tablo yoksa izin ver
END;
$$;

-- update_subscription_status fonksiyonu
DROP FUNCTION IF EXISTS public.update_subscription_status(uuid, text, uuid, timestamp with time zone);
DROP FUNCTION IF EXISTS public.update_subscription_status(uuid, text, uuid);
DROP FUNCTION IF EXISTS public.update_subscription_status(uuid, text);
CREATE OR REPLACE FUNCTION public.update_subscription_status(
    user_id uuid,
    status text,
    subscription_id uuid DEFAULT NULL,
    expires_at timestamp with time zone DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Profiles tablosunu güncelle
    UPDATE public.profiles 
    SET 
        subscription_status = $2,
        updated_at = NOW()
    WHERE id = $1;
    
    -- User subscriptions tablosunu güncelle (eğer varsa)
    IF $3 IS NOT NULL THEN
        UPDATE public.user_subscriptions 
        SET 
            status = $2,
            end_date = $4,
            updated_at = NOW()
        WHERE id = $3 AND user_id = $1;
    END IF;
EXCEPTION
    WHEN undefined_table THEN
        -- Tablo yoksa sessizce devam et
        NULL;
END;
$$;

-- get_bird_family fonksiyonu
DROP FUNCTION IF EXISTS public.get_bird_family(uuid);
CREATE OR REPLACE FUNCTION public.get_bird_family(bird_id uuid)
RETURNS TABLE(
    father_id uuid,
    mother_id uuid,
    father_name text,
    mother_name text,
    father_ring_number text,
    mother_ring_number text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.father_id,
        b.mother_id,
        father.name as father_name,
        mother.name as mother_name,
        father.ring_number as father_ring_number,
        mother.ring_number as mother_ring_number
    FROM public.birds b
    LEFT JOIN public.birds father ON b.father_id = father.id
    LEFT JOIN public.birds mother ON b.mother_id = mother.id
    WHERE b.id = $1;
EXCEPTION
    WHEN undefined_table THEN
        -- Tablo henüz oluşturulmamışsa boş sonuç döndür
        RETURN;
END;
$$;

-- get_user_statistics fonksiyonu
DROP FUNCTION IF EXISTS public.get_user_statistics(uuid);
CREATE OR REPLACE FUNCTION public.get_user_statistics(user_id uuid)
RETURNS TABLE(
    total_birds integer,
    total_eggs integer,
    total_chicks integer,
    total_incubations integer,
    active_incubations integer,
    hatched_eggs integer,
    failed_eggs integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(birds.count, 0) as total_birds,
        COALESCE(eggs.count, 0) as total_eggs,
        COALESCE(chicks.count, 0) as total_chicks,
        COALESCE(incubations.count, 0) as total_incubations,
        COALESCE(active_incubations.count, 0) as active_incubations,
        COALESCE(hatched_eggs.count, 0) as hatched_eggs,
        COALESCE(failed_eggs.count, 0) as failed_eggs
    FROM 
        (SELECT COUNT(*) as count FROM public.birds WHERE user_id = $1) birds,
        (SELECT COUNT(*) as count FROM public.eggs WHERE user_id = $1) eggs,
        (SELECT COUNT(*) as count FROM public.chicks WHERE user_id = $1) chicks,
        (SELECT COUNT(*) as count FROM public.incubations WHERE user_id = $1) incubations,
        (SELECT COUNT(*) as count FROM public.incubations WHERE user_id = $1 AND status = 'active') active_incubations,
        (SELECT COUNT(*) as count FROM public.eggs WHERE user_id = $1 AND status = 'hatched') hatched_eggs,
        (SELECT COUNT(*) as count FROM public.eggs WHERE user_id = $1 AND status = 'failed') failed_eggs;
EXCEPTION
    WHEN undefined_table THEN
        -- Tablo yoksa sıfır değerler döndür
        RETURN QUERY SELECT 0, 0, 0, 0, 0, 0, 0;
END;
$$;

-- 3. RLS Politikalarını Düzeltme (auth_rls_initplan ve multiple_permissive_policies)

-- public.user_subscriptions için RLS politikaları
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can insert own subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can update own subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can manage own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can manage own subscriptions" ON public.user_subscriptions FOR ALL USING ((SELECT auth.uid()) = user_id);

-- public.subscription_usage için RLS politikaları
DROP POLICY IF EXISTS "Users can view own usage" ON public.subscription_usage;
DROP POLICY IF EXISTS "Users can insert own usage" ON public.subscription_usage;
DROP POLICY IF EXISTS "Users can update own usage" ON public.subscription_usage;
DROP POLICY IF EXISTS "Users can manage own usage" ON public.subscription_usage;
CREATE POLICY "Users can manage own usage" ON public.subscription_usage FOR ALL USING ((SELECT auth.uid()) = user_id);

-- public.subscription_events için RLS politikası
DROP POLICY IF EXISTS "Users can view own events" ON public.subscription_events;
CREATE POLICY "Users can view own events" ON public.subscription_events FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- public.profiles için RLS politikaları
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own subscription status" ON public.profiles;
DROP POLICY IF EXISTS "Users can manage their own profiles" ON public.profiles;
CREATE POLICY "Users can manage their own profiles" ON public.profiles FOR ALL USING ((SELECT auth.uid()) = id);

-- public.user_notification_settings için RLS politikaları
DROP POLICY IF EXISTS "Users can view own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can insert own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can update own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can delete own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can manage own notification settings" ON public.user_notification_settings;
CREATE POLICY "Users can manage own notification settings" ON public.user_notification_settings FOR ALL USING ((SELECT auth.uid()) = user_id);

-- 4. Güvenlik kontrolü
SELECT 
    'Security Status Check' as check_type,
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
WHERE proname IN ('handle_updated_at', 'is_user_premium', 'check_feature_limit', 'update_subscription_status', 'get_bird_family', 'get_user_statistics')
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 5. RLS Politika Optimizasyonu Kontrolü
SELECT 
    'RLS Policy Optimization Check' as check_type,
    tablename,
    policyname,
    cmd as operation,
    CASE 
        WHEN qual LIKE '%(SELECT auth.uid())%' OR with_check LIKE '%(SELECT auth.uid())%' THEN '✅ Optimized'
        WHEN qual LIKE '%auth.uid()%' OR with_check LIKE '%auth.uid()%' THEN '❌ Needs Optimization'
        ELSE '✅ No auth.uid() usage'
    END as optimization_status
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('user_subscriptions', 'subscription_usage', 'subscription_events', 'profiles', 'user_notification_settings')
ORDER BY tablename, cmd;

-- Başarı mesajı
SELECT 'Güvenlik uyarıları başarıyla düzeltildi!' as status; 