-- Subscription Sistemi için Eksik Tabloları Düzelt
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. SUBSCRIPTION_PLANS TABLOSU (Abonelik planları)
CREATE TABLE IF NOT EXISTS public.subscription_plans (
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

-- 2. USER_SUBSCRIPTIONS TABLOSU (Kullanıcı abonelikleri)
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
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

-- 3. PROFILES TABLOSUNA PREMIUM ALANLARI EKLEME
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'free',
ADD COLUMN IF NOT EXISTS subscription_plan_id UUID REFERENCES public.subscription_plans(id),
ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMP WITH TIME ZONE;

-- 4. INDEXLER
CREATE INDEX IF NOT EXISTS idx_subscription_plans_active ON public.subscription_plans(is_active);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON public.user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_end_date ON public.user_subscriptions(end_date);
CREATE INDEX IF NOT EXISTS idx_profiles_subscription_status ON public.profiles(subscription_status);

-- 5. TRIGGER'LAR
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER handle_subscription_plans_updated_at
  BEFORE UPDATE ON public.subscription_plans
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_user_subscriptions_updated_at
  BEFORE UPDATE ON public.user_subscriptions
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- 6. VARSayılan PLANLAR
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
)
ON CONFLICT (name) DO NOTHING;

-- 7. RLS POLİTİKALARI

-- Subscription plans tablosu için RLS
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Subscription plans are viewable by everyone" ON public.subscription_plans
  FOR SELECT USING (is_active = true);

-- User subscriptions tablosu için RLS
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscriptions" ON public.user_subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscriptions" ON public.user_subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscriptions" ON public.user_subscriptions
  FOR UPDATE USING (auth.uid() = user_id);

-- 8. Varsayılan kullanıcıları ücretsiz plana ata
UPDATE public.profiles 
SET subscription_status = 'free'
WHERE subscription_status IS NULL;

-- 9. REALTIME ENABLE
ALTER PUBLICATION supabase_realtime ADD TABLE public.subscription_plans;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_subscriptions;

-- 10. TAMAMLANDI MESAJI
SELECT 'Subscription tables created successfully' as message; 