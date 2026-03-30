
-- =============================================
-- BATCH 4: Bildirim Sistemi
-- =============================================

-- 1. Notification Schedules (Zamanlanmış toplu bildirimler)
CREATE TABLE notification_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text,
  type text NOT NULL DEFAULT 'custom',
  schedule_type text NOT NULL DEFAULT 'once' CHECK (schedule_type IN ('once', 'daily', 'weekly', 'monthly')),
  scheduled_at timestamptz NOT NULL,
  repeat_interval_minutes int,
  entity_type text,
  entity_id uuid,
  is_active boolean NOT NULL DEFAULT true,
  last_triggered_at timestamptz,
  next_trigger_at timestamptz,
  max_occurrences int,
  occurrence_count int NOT NULL DEFAULT 0,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_notification_schedules_user_id ON notification_schedules(user_id);
CREATE INDEX idx_notification_schedules_next ON notification_schedules(next_trigger_at, is_active);

ALTER TABLE notification_schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own schedules" ON notification_schedules
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 2. FCM Tokens (Firebase Cloud Messaging)
CREATE TABLE fcm_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token text NOT NULL,
  device_id text,
  platform text NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  is_active boolean NOT NULL DEFAULT true,
  last_used_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_fcm_tokens_user_id ON fcm_tokens(user_id);
CREATE UNIQUE INDEX idx_fcm_tokens_token ON fcm_tokens(token);

ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own tokens" ON fcm_tokens
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 3. Web Push Subscriptions (PWA push)
CREATE TABLE web_push_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  endpoint text NOT NULL,
  p256dh text NOT NULL,
  auth_key text NOT NULL,
  user_agent text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_web_push_user_id ON web_push_subscriptions(user_id);
CREATE UNIQUE INDEX idx_web_push_endpoint ON web_push_subscriptions(endpoint);

ALTER TABLE web_push_subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own subscriptions" ON web_push_subscriptions
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 4. Notification History (Gönderilen bildirimlerin tarihçesi)
CREATE TABLE notification_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_id uuid REFERENCES notifications(id) ON DELETE SET NULL,
  schedule_id uuid REFERENCES notification_schedules(id) ON DELETE SET NULL,
  title text NOT NULL,
  body text,
  type text NOT NULL DEFAULT 'custom',
  channel text NOT NULL DEFAULT 'push' CHECK (channel IN ('push', 'in_app', 'email', 'sms', 'web_push')),
  status text NOT NULL DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'read', 'failed', 'bounced')),
  error_message text,
  metadata jsonb DEFAULT '{}'::jsonb,
  sent_at timestamptz DEFAULT now(),
  delivered_at timestamptz,
  read_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_notification_history_user_id ON notification_history(user_id);
CREATE INDEX idx_notification_history_sent ON notification_history(sent_at);
CREATE INDEX idx_notification_history_status ON notification_history(status);

ALTER TABLE notification_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own history" ON notification_history
  FOR SELECT USING (auth.uid() = user_id);

-- 5. Notification Rate Limits (Spam önleme)
CREATE TABLE notification_rate_limits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_type text NOT NULL,
  window_start timestamptz NOT NULL DEFAULT now(),
  count int NOT NULL DEFAULT 1,
  max_count int NOT NULL DEFAULT 10,
  window_duration_minutes int NOT NULL DEFAULT 60,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_notification_rate_user_type ON notification_rate_limits(user_id, notification_type);

ALTER TABLE notification_rate_limits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own rate limits" ON notification_rate_limits
  FOR SELECT USING (auth.uid() = user_id);
;
