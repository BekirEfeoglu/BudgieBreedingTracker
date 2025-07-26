# 🔧 Premium Subscription Sistemi Kurulum Rehberi

## 🚨 Sorun
"Premium'a Geç" butonları çalışmıyor çünkü:
1. Subscription tabloları eksik
2. Profiles tablosunda subscription alanları yok
3. Premium planları tanımlanmamış

## 🔧 Çözüm Adımları

### 1. Supabase Dashboard'a Gidin
- https://supabase.com/dashboard
- `etkvuonkmmzihsjwbcrl` projesini seçin

### 2. SQL Editor'ı Açın
- Sol menüde **SQL Editor** tıklayın
- **New query** butonuna tıklayın

### 3. Subscription Tablolarını Oluşturun
Aşağıdaki SQL'i kopyalayıp yapıştırın ve **Run** butonuna tıklayın:

```sql
-- Subscription Plans Table
CREATE TABLE IF NOT EXISTS subscription_plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  display_name VARCHAR(100) NOT NULL,
  description TEXT,
  price_monthly DECIMAL(10,2) NOT NULL,
  price_yearly DECIMAL(10,2) NOT NULL,
  features JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Subscriptions Table
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES subscription_plans(id),
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  current_period_start TIMESTAMP WITH TIME ZONE,
  current_period_end TIMESTAMP WITH TIME ZONE,
  trial_start TIMESTAMP WITH TIME ZONE,
  trial_end TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add subscription fields to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(20) DEFAULT 'free',
ADD COLUMN IF NOT EXISTS subscription_plan_id UUID REFERENCES subscription_plans(id),
ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMP WITH TIME ZONE;
```

### 4. Varsayılan Planları Ekleyin
Yeni bir query oluşturun ve şu SQL'i çalıştırın:

```sql
-- Insert default subscription plans
INSERT INTO subscription_plans (name, display_name, description, price_monthly, price_yearly, features) 
SELECT 'free', 'Ücretsiz', 'Temel özellikler', 0.00, 0.00, '{"birds": 3, "incubations": 1, "eggs": 6, "chicks": 3, "notifications": 5}'
WHERE NOT EXISTS (SELECT 1 FROM subscription_plans WHERE name = 'free');

INSERT INTO subscription_plans (name, display_name, description, price_monthly, price_yearly, features) 
SELECT 'premium', 'Premium', 'Sınırsız özellikler ve gelişmiş analitikler', 29.99, 299.99, '{"unlimited_birds": true, "unlimited_incubations": true, "unlimited_eggs": true, "unlimited_chicks": true, "unlimited_notifications": true, "cloud_sync": true, "advanced_stats": true, "genealogy": true, "data_export": true, "ad_free": true, "custom_notifications": true, "auto_backup": true}'
WHERE NOT EXISTS (SELECT 1 FROM subscription_plans WHERE name = 'premium');
```

### 5. RLS Policies Ekleyin
Yeni bir query oluşturun ve şu SQL'i çalıştırın:

```sql
-- RLS Policies for subscription_plans
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active subscription plans" ON subscription_plans
  FOR SELECT USING (is_active = true);

-- RLS Policies for user_subscriptions
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscriptions" ON user_subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscriptions" ON user_subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscriptions" ON user_subscriptions
  FOR UPDATE USING (auth.uid() = user_id);
```

### 6. Database Functions Oluşturun
Yeni bir query oluşturun ve şu SQL'i çalıştırın:

```sql
-- Function to check feature limits
CREATE OR REPLACE FUNCTION check_feature_limit(
  user_uuid UUID,
  feature_name TEXT,
  current_count INTEGER DEFAULT 0
) RETURNS BOOLEAN AS $$
DECLARE
  user_profile RECORD;
  plan_features JSONB;
  limit_value INTEGER;
BEGIN
  -- Get user profile
  SELECT subscription_status, subscription_plan_id INTO user_profile
  FROM profiles WHERE id = user_uuid;
  
  -- If premium, no limits
  IF user_profile.subscription_status = 'premium' THEN
    RETURN TRUE;
  END IF;
  
  -- Get plan features
  SELECT features INTO plan_features
  FROM subscription_plans 
  WHERE id = user_profile.subscription_plan_id;
  
  -- If no plan or free plan, use default limits
  IF plan_features IS NULL THEN
    plan_features := '{"birds": 3, "incubations": 1, "eggs": 6, "chicks": 3, "notifications": 5}'::JSONB;
  END IF;
  
  -- Get limit for feature
  limit_value := COALESCE((plan_features->>feature_name)::INTEGER, 10);
  
  -- Check if within limit
  RETURN current_count < limit_value;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update subscription status
CREATE OR REPLACE FUNCTION update_subscription_status(
  user_uuid UUID,
  new_status TEXT,
  plan_id UUID DEFAULT NULL,
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
  UPDATE profiles 
  SET 
    subscription_status = new_status,
    subscription_plan_id = plan_id,
    subscription_expires_at = expires_at,
    updated_at = NOW()
  WHERE id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## 🧪 Test Etme

### 1. Uygulamayı Yenileyin
- Browser'ı yenileyin (F5)
- Console'u açın (F12)

### 2. Premium Sayfasına Gidin
- `/premium` sayfasına gidin
- Sayfa yüklenirken hata olmamalı

### 3. Premium'a Geç Butonunu Test Edin
- "Premium'a Geç" butonuna tıklayın
- Console'da başarı mesajı görmelisiniz
- Sayfa yenilenmeli ve premium durumu güncellenmeli

### 4. Trial Butonunu Test Edin
- "3 Gün Ücretsiz Dene" butonuna tıklayın
- Console'da trial başlatma mesajı görmelisiniz

## 📊 Beklenen Sonuç

✅ **Subscription tabloları oluşturuldu**  
✅ **Varsayılan planlar eklendi**  
✅ **RLS policies aktif**  
✅ **Database functions hazır**  
✅ **Premium'a Geç butonu çalışıyor**  
✅ **Trial başlatma çalışıyor**  
✅ **Toast mesajları gösteriliyor**  

## 🔍 Sorun Giderme

### Eğer Hala Çalışmıyorsa:
1. Console'da hata mesajlarını kontrol edin
2. Supabase Dashboard'da tabloların oluşturulduğunu doğrulayın
3. RLS policies'in aktif olduğunu kontrol edin
4. Database functions'ın oluşturulduğunu kontrol edin

### Console'da Göreceğiniz Mesajlar:
```
✅ Premium abonelik başarıyla aktifleştirildi
✅ Trial başarıyla başlatıldı
```

---

**💡 İpucu**: Tüm SQL komutlarını sırayla çalıştırdıktan sonra uygulamayı yeniden başlatın. 