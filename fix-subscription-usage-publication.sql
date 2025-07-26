-- subscription_usage tablosu publication çakışmasını düzelt
-- Bu script tablonun zaten publication'da olup olmadığını kontrol eder ve güvenli şekilde ekler

-- 1. Önce mevcut durumu kontrol et
SELECT 'Mevcut publication durumu:' as info;
SELECT 
    schemaname,
    tablename,
    pubname
FROM pg_publication_tables 
WHERE tablename = 'subscription_usage';

-- 2. subscription_usage tablosunu güvenli şekilde publication'a ekle
DO $$
BEGIN
    -- Tablo publication'da var mı kontrol et
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE tablename = 'subscription_usage' 
        AND pubname = 'supabase_realtime'
    ) THEN
        -- Tablo yoksa ekle
        ALTER PUBLICATION supabase_realtime ADD TABLE public.subscription_usage;
        RAISE NOTICE 'subscription_usage tablosu publication''a eklendi';
    ELSE
        RAISE NOTICE 'subscription_usage tablosu zaten publication''da mevcut';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Hata: %', SQLERRM;
END $$;

-- 3. Diğer subscription tablolarını da güvenli şekilde ekle
DO $$
BEGIN
    -- subscription_plans
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE tablename = 'subscription_plans' 
        AND pubname = 'supabase_realtime'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.subscription_plans;
        RAISE NOTICE 'subscription_plans tablosu publication''a eklendi';
    END IF;
    
    -- user_subscriptions
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE tablename = 'user_subscriptions' 
        AND pubname = 'supabase_realtime'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.user_subscriptions;
        RAISE NOTICE 'user_subscriptions tablosu publication''a eklendi';
    END IF;
    
    -- subscription_events
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE tablename = 'subscription_events' 
        AND pubname = 'supabase_realtime'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.subscription_events;
        RAISE NOTICE 'subscription_events tablosu publication''a eklendi';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Hata: %', SQLERRM;
END $$;

-- 4. Son durumu kontrol et
SELECT 'Son publication durumu:' as info;
SELECT 
    schemaname,
    tablename,
    pubname
FROM pg_publication_tables 
WHERE tablename LIKE 'subscription%'
ORDER BY tablename;

-- 5. Tüm publication üyelerini listele
SELECT 'Tüm publication üyeleri:' as info;
SELECT 
    schemaname,
    tablename,
    pubname
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
ORDER BY tablename; 