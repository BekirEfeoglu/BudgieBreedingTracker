
-- =============================================
-- BATCH 2: Kullanıcı & Abonelik
-- =============================================

-- 1. User Preferences (Kullanıcı ayarları)
CREATE TABLE user_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  theme text NOT NULL DEFAULT 'system' CHECK (theme IN ('light', 'dark', 'system')),
  language text NOT NULL DEFAULT 'tr' CHECK (language IN ('tr', 'en', 'de')),
  date_format text NOT NULL DEFAULT 'dd.MM.yyyy',
  time_format text NOT NULL DEFAULT 'HH:mm',
  first_day_of_week int NOT NULL DEFAULT 1 CHECK (first_day_of_week BETWEEN 0 AND 6),
  show_ring_number boolean NOT NULL DEFAULT true,
  show_cage_number boolean NOT NULL DEFAULT true,
  default_bird_species text NOT NULL DEFAULT 'budgie',
  compact_list_view boolean NOT NULL DEFAULT false,
  auto_backup_enabled boolean NOT NULL DEFAULT false,
  auto_backup_interval_hours int NOT NULL DEFAULT 24,
  data_sharing_enabled boolean NOT NULL DEFAULT false,
  analytics_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);

ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own preferences" ON user_preferences
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 2. User Sessions (Aktif oturum takibi)
CREATE TABLE user_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_info text,
  platform text CHECK (platform IN ('android', 'ios', 'web', 'windows', 'macos', 'linux')),
  app_version text,
  ip_address inet,
  is_active boolean NOT NULL DEFAULT true,
  last_active_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz
);

CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_active ON user_sessions(is_active, last_active_at);

ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own sessions" ON user_sessions
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own sessions" ON user_sessions
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 3. Subscription Plans (Premium plan tanımları)
CREATE TABLE subscription_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  price_monthly decimal(10,2) NOT NULL DEFAULT 0,
  price_yearly decimal(10,2) NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'TRY',
  features jsonb NOT NULL DEFAULT '[]'::jsonb,
  max_birds int,
  max_breeding_pairs int,
  max_photos_per_bird int NOT NULL DEFAULT 10,
  has_statistics boolean NOT NULL DEFAULT false,
  has_genealogy boolean NOT NULL DEFAULT false,
  has_genetics boolean NOT NULL DEFAULT false,
  has_export boolean NOT NULL DEFAULT false,
  has_community boolean NOT NULL DEFAULT false,
  has_priority_support boolean NOT NULL DEFAULT false,
  is_active boolean NOT NULL DEFAULT true,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view active plans" ON subscription_plans
  FOR SELECT USING (is_active = true);

-- Insert default plans
INSERT INTO subscription_plans (name, description, price_monthly, price_yearly, features, max_birds, max_breeding_pairs, has_statistics, has_genealogy, has_genetics, has_export, has_community, sort_order) VALUES
  ('Ücretsiz', 'Temel özellikler', 0, 0, '["5 kuş", "2 eşleşme", "Temel takip"]'::jsonb, 5, 2, false, false, false, false, false, 0),
  ('Premium', 'Tüm özellikler', 49.99, 399.99, '["Sınırsız kuş", "Sınırsız eşleşme", "İstatistikler", "Soy ağacı", "Genetik", "Dışa aktarma", "Topluluk"]'::jsonb, null, null, true, true, true, true, true, 1);

-- 4. User Subscriptions (Kullanıcı abonelik durumları)
CREATE TABLE user_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id uuid REFERENCES subscription_plans(id),
  plan text NOT NULL DEFAULT 'free',
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'canceled', 'expired', 'trial', 'past_due')),
  provider text CHECK (provider IN ('revenuecat', 'stripe', 'apple', 'google', 'manual')),
  provider_subscription_id text,
  current_period_start timestamptz,
  current_period_end timestamptz,
  cancel_at_period_end boolean NOT NULL DEFAULT false,
  trial_start timestamptz,
  trial_end timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE UNIQUE INDEX idx_user_subscriptions_active ON user_subscriptions(user_id) WHERE status IN ('active', 'trial');

ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own subscriptions" ON user_subscriptions
  FOR SELECT USING (auth.uid() = user_id);

-- 5. Feedback (Kullanıcı geri bildirimleri)
CREATE TABLE feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL DEFAULT 'general' CHECK (type IN ('bug', 'feature', 'general', 'complaint', 'praise')),
  subject text NOT NULL,
  message text NOT NULL,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed', 'wont_fix')),
  priority text NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'critical')),
  admin_response text,
  app_version text,
  platform text,
  screenshot_urls jsonb DEFAULT '[]'::jsonb,
  resolved_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_feedback_user_id ON feedback(user_id);
CREATE INDEX idx_feedback_status ON feedback(status);

ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own feedback" ON feedback
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins can view all feedback" ON feedback
  FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM admin_users)
  );
;
