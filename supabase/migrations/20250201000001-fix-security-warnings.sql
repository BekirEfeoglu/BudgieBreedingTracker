-- Güvenlik Uyarılarını Düzeltme Migration
-- Bu migration, Supabase güvenlik uyarılarını düzeltir

-- 1. is_user_premium fonksiyonunu güvenli hale getir
CREATE OR REPLACE FUNCTION public.is_user_premium(user_uuid uuid)
RETURNS BOOLEAN AS $$
DECLARE
  subscription_status TEXT;
  subscription_expires TIMESTAMP WITH TIME ZONE;
BEGIN
  SELECT 
    p.subscription_status,
    p.subscription_expires_at
  INTO 
    subscription_status,
    subscription_expires
  FROM public.profiles p
  WHERE p.id = user_uuid;
  
  RETURN subscription_status = 'premium' AND 
         (subscription_expires IS NULL OR subscription_expires > now());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. check_feature_limit fonksiyonunu güvenli hale getir
CREATE OR REPLACE FUNCTION public.check_feature_limit(
  user_uuid uuid,
  feature_name text,
  current_count integer DEFAULT 0
)
RETURNS BOOLEAN AS $$
DECLARE
  user_limit INTEGER;
  user_status TEXT;
BEGIN
  -- Kullanıcının premium durumunu kontrol et
  SELECT subscription_status INTO user_status
  FROM public.profiles
  WHERE id = user_uuid;
  
  -- Premium kullanıcılar için sınırsız
  IF user_status = 'premium' THEN
    RETURN true;
  END IF;
  
  -- Ücretsiz kullanıcılar için limit kontrolü
  SELECT 
    CASE 
      WHEN feature_name = 'birds' THEN 3
      WHEN feature_name = 'incubations' THEN 1
      WHEN feature_name = 'eggs' THEN 6
      WHEN feature_name = 'chicks' THEN 3
      WHEN feature_name = 'notifications' THEN 5
      ELSE 0
    END INTO user_limit;
  
  RETURN current_count < user_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. update_subscription_status fonksiyonunu güvenli hale getir
CREATE OR REPLACE FUNCTION public.update_subscription_status(
  user_uuid uuid,
  new_status text,
  plan_id uuid DEFAULT NULL,
  expires_at timestamp with time zone DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  UPDATE public.profiles
  SET 
    subscription_status = new_status,
    subscription_plan_id = plan_id,
    subscription_expires_at = expires_at,
    updated_at = now()
  WHERE id = user_uuid;
  
  -- Abonelik olayını kaydet (eğer subscription_events tablosu varsa)
  BEGIN
    INSERT INTO public.subscription_events (user_id, event_type, event_data)
    VALUES (
      user_uuid,
      'status_changed',
      jsonb_build_object(
        'old_status', (SELECT subscription_status FROM public.profiles WHERE id = user_uuid),
        'new_status', new_status,
        'plan_id', plan_id,
        'expires_at', expires_at
      )
    );
  EXCEPTION
    WHEN undefined_table THEN
      -- Tablo yoksa sessizce devam et
      NULL;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. handle_updated_at fonksiyonunu güvenli hale getir
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5. get_bird_family fonksiyonunu güvenli hale getir
CREATE OR REPLACE FUNCTION public.get_bird_family(bird_id uuid, user_id uuid)
RETURNS TABLE(
  relation_type text,
  bird_id uuid,
  bird_name text,
  bird_gender text,
  is_chick boolean
) AS $$
BEGIN
  RETURN QUERY
  -- Parents
  SELECT 'father'::text, b.id, b.name, b.gender, false::boolean
  FROM public.birds b
  WHERE b.id = (SELECT father_id FROM public.birds WHERE id = bird_id AND user_id = user_id)
  
  UNION ALL
  
  SELECT 'mother'::text, b.id, b.name, b.gender, false::boolean
  FROM public.birds b
  WHERE b.id = (SELECT mother_id FROM public.birds WHERE id = bird_id AND user_id = user_id)
  
  UNION ALL
  
  -- Children (birds)
  SELECT 'child'::text, b.id, b.name, b.gender, false::boolean
  FROM public.birds b
  WHERE (b.father_id = bird_id OR b.mother_id = bird_id) AND b.user_id = user_id
  
  UNION ALL
  
  -- Children (chicks)
  SELECT 'child'::text, c.id, c.name, c.gender, true::boolean
  FROM public.chicks c
  WHERE (c.father_id = bird_id OR c.mother_id = bird_id) AND c.user_id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- 6. get_user_statistics fonksiyonunu güvenli hale getir
CREATE OR REPLACE FUNCTION public.get_user_statistics(user_id uuid)
RETURNS TABLE(
  total_birds bigint,
  total_chicks bigint,
  total_eggs bigint,
  active_incubations bigint,
  total_photos bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*) FROM public.birds WHERE user_id = get_user_statistics.user_id),
    (SELECT COUNT(*) FROM public.chicks WHERE user_id = get_user_statistics.user_id),
    (SELECT COUNT(*) FROM public.eggs WHERE user_id = get_user_statistics.user_id),
    (SELECT COUNT(*) FROM public.incubations WHERE user_id = get_user_statistics.user_id AND start_date >= CURRENT_DATE - INTERVAL '30 days'),
    (SELECT COUNT(*) FROM public.photos WHERE user_id = get_user_statistics.user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- Migration tamamlandı mesajı
SELECT 'Security warnings fixed successfully' as message; 