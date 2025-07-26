-- Migration Çakışmalarını Düzeltme
-- Bu script migration dosyalarındaki çakışmaları çözer

-- 1. Önce mevcut tabloları kontrol et
SELECT 'Mevcut tablolar:' as info;
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE '%subscription%'
ORDER BY table_name;

-- 2. subscription_plans tablosunu düzelt
-- Önce tabloyu sil ve yeniden oluştur
DROP TABLE IF EXISTS public.subscription_plans CASCADE;

CREATE TABLE public.subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  description TEXT,
  price_monthly DECIMAL(10,2) NOT NULL,
  price_yearly DECIMAL(10,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'TRY',
  features JSONB NOT NULL DEFAULT '[]',
  limits JSONB NOT NULL DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 3. user_subscriptions tablosunu düzelt
DROP TABLE IF EXISTS public.user_subscriptions CASCADE;

CREATE TABLE public.user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES public.subscription_plans(id),
  status TEXT CHECK (status IN ('active', 'cancelled', 'expired', 'trial')) NOT NULL DEFAULT 'trial',
  billing_cycle TEXT CHECK (billing_cycle IN ('monthly', 'yearly')) NOT NULL DEFAULT 'monthly',
  start_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  end_date TIMESTAMP WITH TIME ZONE,
  trial_end_date TIMESTAMP WITH TIME ZONE,
  payment_provider TEXT,
  payment_provider_subscription_id TEXT,
  auto_renew BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 4. subscription_usage tablosunu oluştur
CREATE TABLE IF NOT EXISTS public.subscription_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subscription_id UUID NOT NULL REFERENCES public.user_subscriptions(id) ON DELETE CASCADE,
  feature_name TEXT NOT NULL,
  usage_count INTEGER NOT NULL DEFAULT 0,
  limit_count INTEGER,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 5. subscription_events tablosunu oluştur
CREATE TABLE IF NOT EXISTS public.subscription_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.user_subscriptions(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL,
  event_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 6. profiles tablosuna premium alanları ekle
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'free',
ADD COLUMN IF NOT EXISTS subscription_plan_id UUID REFERENCES public.subscription_plans(id),
ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMP WITH TIME ZONE;

-- 7. Indexleri oluştur
CREATE INDEX IF NOT EXISTS idx_subscription_plans_active ON public.subscription_plans(is_active);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON public.user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_end_date ON public.user_subscriptions(end_date);
CREATE INDEX IF NOT EXISTS idx_subscription_usage_user_id ON public.subscription_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_usage_period ON public.subscription_usage(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_subscription_events_user_id ON public.subscription_events(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_events_created_at ON public.subscription_events(created_at);
CREATE INDEX IF NOT EXISTS idx_profiles_subscription_status ON public.profiles(subscription_status);

-- 8. Trigger'ları oluştur
-- handle_updated_at fonksiyonunu oluştur (eğer yoksa)
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger'ları güvenli şekilde oluştur
DO $$
BEGIN
    -- subscription_plans trigger
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'handle_subscription_plans_updated_at' 
        AND tgrelid = 'public.subscription_plans'::regclass
    ) THEN
        CREATE TRIGGER handle_subscription_plans_updated_at
          BEFORE UPDATE ON public.subscription_plans
          FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
    END IF;
    
    -- user_subscriptions trigger
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'handle_user_subscriptions_updated_at' 
        AND tgrelid = 'public.user_subscriptions'::regclass
    ) THEN
        CREATE TRIGGER handle_user_subscriptions_updated_at
          BEFORE UPDATE ON public.user_subscriptions
          FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
    END IF;
    
    -- subscription_usage trigger
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'handle_subscription_usage_updated_at' 
        AND tgrelid = 'public.subscription_usage'::regclass
    ) THEN
        CREATE TRIGGER handle_subscription_usage_updated_at
          BEFORE UPDATE ON public.subscription_usage
          FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Hata olursa sessizce devam et
        NULL;
END $$;

-- 9. Varsayılan planları ekle
INSERT INTO public.subscription_plans (name, display_name, description, price_monthly, price_yearly, currency, features, limits) VALUES
(
  'free',
  'Ücretsiz',
  'Temel özellikler ile sınırlı kullanım',
  0.00,
  0.00,
  'TRY',
  '["temel_kuş_takibi", "temel_yumurta_takibi", "temel_yavru_takibi", "reklamlar"]',
  '{"max_birds": 3, "max_incubations": 1, "max_eggs": 6, "max_chicks": 3, "cloud_sync": false, "advanced_stats": false, "genealogy": false, "export": false, "notifications": 5}'
),
(
  'premium',
  'Premium',
  'Sınırsız özellikler ve gelişmiş analitikler',
  29.99,
  299.99,
  'TRY',
  '["sınırsız_kuş_takibi", "sınırsız_yumurta_takibi", "sınırsız_yavru_takibi", "bulut_senkronizasyonu", "gelişmiş_istatistikler", "soyağacı_görüntüleme", "veri_dışa_aktarma", "reklamsız_deneyim", "özel_bildirimler", "otomatik_yedekleme"]',
  '{"max_birds": -1, "max_incubations": -1, "max_eggs": -1, "max_chicks": -1, "cloud_sync": true, "advanced_stats": true, "genealogy": true, "export": true, "notifications": -1}'
);

-- 10. RLS politikalarını oluştur
-- Subscription plans tablosu için RLS
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Subscription plans are viewable by everyone" ON public.subscription_plans;
CREATE POLICY "Subscription plans are viewable by everyone" ON public.subscription_plans
  FOR SELECT USING (is_active = true);

-- User subscriptions tablosu için RLS
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can view own subscriptions" ON public.user_subscriptions
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can insert own subscriptions" ON public.user_subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can update own subscriptions" ON public.user_subscriptions
  FOR UPDATE USING (auth.uid() = user_id);

-- Subscription usage tablosu için RLS
ALTER TABLE public.subscription_usage ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own usage" ON public.subscription_usage;
CREATE POLICY "Users can view own usage" ON public.subscription_usage
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own usage" ON public.subscription_usage;
CREATE POLICY "Users can insert own usage" ON public.subscription_usage
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own usage" ON public.subscription_usage;
CREATE POLICY "Users can update own usage" ON public.subscription_usage
  FOR UPDATE USING (auth.uid() = user_id);

-- Subscription events tablosu için RLS
ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own events" ON public.subscription_events;
CREATE POLICY "Users can view own events" ON public.subscription_events
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert events" ON public.subscription_events;
CREATE POLICY "System can insert events" ON public.subscription_events
  FOR INSERT WITH CHECK (true);

-- 11. Fonksiyonları oluştur
-- Kullanıcının premium durumunu kontrol eden fonksiyon
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

-- Kullanıcının özellik limitini kontrol eden fonksiyon
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

-- Abonelik durumunu güncelleyen fonksiyon
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
  
  -- Abonelik olayını kaydet
  INSERT INTO public.subscription_events (user_id, event_type, event_data)
  VALUES (
    user_uuid,
    'status_changed',
    jsonb_build_object(
      'old_status', (SELECT subscription_status FROM public.profiles WHERE id = user_uuid),
      'old_status', (SELECT subscription_status FROM public.profiles WHERE id = user_uuid),
      'new_status', new_status,
      'plan_id', plan_id,
      'expires_at', expires_at
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 12. Varsayılan kullanıcıları ücretsiz plana ata
UPDATE public.profiles 
SET subscription_status = 'free'
WHERE subscription_status IS NULL;

-- 13. Realtime'i güvenli şekilde etkinleştir
DO $$
BEGIN
    -- subscription_plans
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE tablename = 'subscription_plans' 
        AND pubname = 'supabase_realtime'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.subscription_plans;
    END IF;
    
    -- user_subscriptions
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE tablename = 'user_subscriptions' 
        AND pubname = 'supabase_realtime'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.user_subscriptions;
    END IF;
    
    -- subscription_usage
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE tablename = 'subscription_usage' 
        AND pubname = 'supabase_realtime'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.subscription_usage;
    END IF;
    
    -- subscription_events
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE tablename = 'subscription_events' 
        AND pubname = 'supabase_realtime'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.subscription_events;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Hata olursa sessizce devam et
        NULL;
END $$;

-- 14. Son durumu kontrol et
SELECT 'Migration çakışmaları düzeltildi!' as message;
SELECT 'Subscription plans tablosu:' as info;
SELECT id, name, display_name, is_active FROM public.subscription_plans ORDER BY name; 