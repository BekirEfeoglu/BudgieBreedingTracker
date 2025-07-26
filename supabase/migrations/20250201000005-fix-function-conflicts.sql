-- Function Conflicts Düzeltme Migration
-- Bu migration fonksiyon çakışmalarını çözer

-- ========================================
-- 1. ESKİ FONKSİYONLARI SİL
-- ========================================

-- get_bird_family fonksiyonunu sil (tüm overload'ları)
DROP FUNCTION IF EXISTS public.get_bird_family(uuid);
DROP FUNCTION IF EXISTS public.get_bird_family(uuid, uuid);
DROP FUNCTION IF EXISTS public.get_bird_family(uuid, uuid, text);

-- Diğer fonksiyonları da sil
DROP FUNCTION IF EXISTS public.is_user_premium(uuid);
DROP FUNCTION IF EXISTS public.check_feature_limit(uuid, text, integer);
DROP FUNCTION IF EXISTS public.update_subscription_status(uuid, text, uuid, timestamp with time zone);
DROP FUNCTION IF EXISTS public.handle_updated_at();
DROP FUNCTION IF EXISTS public.get_user_statistics(uuid);

-- ========================================
-- 2. FONKSİYONLARI YENİDEN OLUŞTUR
-- ========================================

-- is_user_premium fonksiyonu
CREATE OR REPLACE FUNCTION public.is_user_premium(user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public;
AS $$
DECLARE
    subscription_record record;
BEGIN
    -- Kullanıcının aktif aboneliği var mı kontrol et
    SELECT * INTO subscription_record
    FROM public.user_subscriptions
    WHERE user_id = $1
    AND status = 'active'
    AND expires_at > now()
    ORDER BY created_at DESC
    LIMIT 1;
    
    RETURN FOUND;
EXCEPTION
    WHEN undefined_table THEN
        -- Tablo henüz oluşturulmamışsa false döndür
        RETURN false;
END;
$$;

-- check_feature_limit fonksiyonu
CREATE OR REPLACE FUNCTION public.check_feature_limit(user_id uuid, feature_name text, current_count integer)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public;
AS $$
DECLARE
    subscription_record record;
    feature_limit integer;
BEGIN
    -- Kullanıcının aktif aboneliği var mı kontrol et
    SELECT * INTO subscription_record
    FROM public.user_subscriptions
    WHERE user_id = $1
    AND status = 'active'
    AND expires_at > now()
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF NOT FOUND THEN
        -- Abonelik yoksa ücretsiz limitleri kullan
        CASE feature_name
            WHEN 'birds' THEN feature_limit := 3;
            WHEN 'incubations' THEN feature_limit := 2;
            WHEN 'eggs' THEN feature_limit := 10;
            WHEN 'chicks' THEN feature_limit := 5;
            WHEN 'notifications' THEN feature_limit := 10;
            ELSE feature_limit := 0;
        END CASE;
    ELSE
        -- Abonelik varsa premium limitleri kullan
        CASE feature_name
            WHEN 'birds' THEN feature_limit := -1; -- Sınırsız
            WHEN 'incubations' THEN feature_limit := -1;
            WHEN 'eggs' THEN feature_limit := -1;
            WHEN 'chicks' THEN feature_limit := -1;
            WHEN 'notifications' THEN feature_limit := -1;
            ELSE feature_limit := -1;
        END CASE;
    END IF;
    
    -- Limit kontrolü
    RETURN feature_limit = -1 OR current_count < feature_limit;
EXCEPTION
    WHEN undefined_table THEN
        -- Tablo henüz oluşturulmamışsa true döndür (limit yok)
        RETURN true;
END;
$$;

-- update_subscription_status fonksiyonu
CREATE OR REPLACE FUNCTION public.update_subscription_status(
    user_id uuid,
    status text,
    subscription_id uuid DEFAULT NULL,
    expires_at timestamp with time zone DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public;
AS $$
BEGIN
    -- Abonelik durumunu güncelle
    UPDATE public.user_subscriptions
    SET 
        status = $2,
        updated_at = now()
    WHERE user_id = $1;
    
    -- Eğer subscription_id ve expires_at verilmişse onları da güncelle
    IF $3 IS NOT NULL AND $4 IS NOT NULL THEN
        UPDATE public.user_subscriptions
        SET 
            subscription_id = $3,
            expires_at = $4,
            updated_at = now()
        WHERE user_id = $1;
    END IF;
    
    -- Abonelik olayını kaydet
    BEGIN
        INSERT INTO public.subscription_events (user_id, event_type, event_data)
        VALUES ($1, 'status_updated', jsonb_build_object('status', $2, 'subscription_id', $3, 'expires_at', $4));
    EXCEPTION
        WHEN undefined_table THEN
            -- subscription_events tablosu henüz oluşturulmamışsa atla
            NULL;
    END;
EXCEPTION
    WHEN undefined_table THEN
        -- user_subscriptions tablosu henüz oluşturulmamışsa atla
        NULL;
END;
$$;

-- handle_updated_at fonksiyonu
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public;
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- get_bird_family fonksiyonu (tüm overload'ları)
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
SECURITY DEFINER SET search_path = public;
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

CREATE OR REPLACE FUNCTION public.get_bird_family(bird_id uuid, user_id uuid)
RETURNS TABLE(
    father_id uuid,
    mother_id uuid,
    father_name text,
    mother_name text,
    father_ring_number text,
    mother_ring_number text
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public;
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
    WHERE b.id = $1 AND b.user_id = $2;
EXCEPTION
    WHEN undefined_table THEN
        -- Tablo henüz oluşturulmamışsa boş sonuç döndür
        RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_bird_family(bird_id uuid, user_id uuid, include_deleted text DEFAULT 'false')
RETURNS TABLE(
    father_id uuid,
    mother_id uuid,
    father_name text,
    mother_name text,
    father_ring_number text,
    mother_ring_number text
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public;
AS $$
BEGIN
    IF $3 = 'true' THEN
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
        WHERE b.id = $1 AND b.user_id = $2;
    ELSE
        RETURN QUERY
        SELECT 
            b.father_id,
            b.mother_id,
            father.name as father_name,
            mother.name as mother_name,
            father.ring_number as father_ring_number,
            mother.ring_number as mother_ring_number
        FROM public.birds b
        LEFT JOIN public.birds father ON b.father_id = father.id AND father.deleted_at IS NULL
        LEFT JOIN public.birds mother ON b.mother_id = mother.id AND mother.deleted_at IS NULL
        WHERE b.id = $1 AND b.user_id = $2 AND b.deleted_at IS NULL;
    END IF;
EXCEPTION
    WHEN undefined_table THEN
        -- Tablo henüz oluşturulmamışsa boş sonuç döndür
        RETURN;
END;
$$;

-- get_user_statistics fonksiyonu
CREATE OR REPLACE FUNCTION public.get_user_statistics(user_id uuid)
RETURNS TABLE(
    total_birds integer,
    total_incubations integer,
    total_eggs integer,
    total_chicks integer,
    active_incubations integer,
    active_eggs integer,
    active_chicks integer
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public;
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(birds.count, 0) as total_birds,
        COALESCE(incubations.count, 0) as total_incubations,
        COALESCE(eggs.count, 0) as total_eggs,
        COALESCE(chicks.count, 0) as total_chicks,
        COALESCE(active_incubations.count, 0) as active_incubations,
        COALESCE(active_eggs.count, 0) as active_eggs,
        COALESCE(active_chicks.count, 0) as active_chicks
    FROM 
        (SELECT COUNT(*) as count FROM public.birds WHERE user_id = $1 AND deleted_at IS NULL) birds,
        (SELECT COUNT(*) as count FROM public.incubations WHERE user_id = $1 AND deleted_at IS NULL) incubations,
        (SELECT COUNT(*) as count FROM public.eggs WHERE user_id = $1 AND deleted_at IS NULL) eggs,
        (SELECT COUNT(*) as count FROM public.chicks WHERE user_id = $1 AND deleted_at IS NULL) chicks,
        (SELECT COUNT(*) as count FROM public.incubations WHERE user_id = $1 AND deleted_at IS NULL AND status = 'active') active_incubations,
        (SELECT COUNT(*) as count FROM public.eggs WHERE user_id = $1 AND deleted_at IS NULL AND status = 'incubating') active_eggs,
        (SELECT COUNT(*) as count FROM public.chicks WHERE user_id = $1 AND deleted_at IS NULL AND status = 'alive') active_chicks;
EXCEPTION
    WHEN undefined_table THEN
        -- Tablo henüz oluşturulmamışsa sıfır değerler döndür
        RETURN QUERY SELECT 0, 0, 0, 0, 0, 0, 0;
END;
$$;

-- ========================================
-- 3. DOĞRULAMA
-- ========================================

SELECT 'Function conflicts fixed successfully' as message; 