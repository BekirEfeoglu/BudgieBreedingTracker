
-- =============================================
-- BATCH 8: Admin & Sistem
-- =============================================

-- 1. Admin Logs (Yönetici işlem kayıtları)
CREATE TABLE admin_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  action text NOT NULL,
  entity_type text,
  entity_id uuid,
  details jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_admin_logs_admin ON admin_logs(admin_user_id);
CREATE INDEX idx_admin_logs_target ON admin_logs(target_user_id);
CREATE INDEX idx_admin_logs_action ON admin_logs(action);
CREATE INDEX idx_admin_logs_date ON admin_logs(created_at);

ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can view logs" ON admin_logs
  FOR SELECT USING (auth.uid() IN (SELECT user_id FROM admin_users));
CREATE POLICY "Admins can insert logs" ON admin_logs
  FOR INSERT WITH CHECK (auth.uid() IN (SELECT user_id FROM admin_users));

-- 2. Admin Sessions (Yönetici oturumları)
CREATE TABLE admin_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id uuid NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
  ip_address inet,
  user_agent text,
  is_active boolean NOT NULL DEFAULT true,
  last_active_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz DEFAULT (now() + interval '8 hours')
);

CREATE INDEX idx_admin_sessions_admin ON admin_sessions(admin_user_id);
CREATE INDEX idx_admin_sessions_active ON admin_sessions(is_active);

ALTER TABLE admin_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can manage own sessions" ON admin_sessions
  FOR ALL USING (
    admin_user_id IN (SELECT id FROM admin_users WHERE user_id = auth.uid())
  );

-- 3. Admin Rate Limits (Yönetici işlem limitleri)
CREATE TABLE admin_rate_limits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action text NOT NULL,
  window_start timestamptz NOT NULL DEFAULT now(),
  count int NOT NULL DEFAULT 1,
  max_count int NOT NULL DEFAULT 100,
  window_duration_minutes int NOT NULL DEFAULT 60,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_admin_rate_admin ON admin_rate_limits(admin_user_id, action);

ALTER TABLE admin_rate_limits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can view own rate limits" ON admin_rate_limits
  FOR SELECT USING (auth.uid() = admin_user_id);

-- 4. System Settings (Global sistem ayarları)
CREATE TABLE system_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE,
  value jsonb NOT NULL,
  description text,
  category text NOT NULL DEFAULT 'general' CHECK (category IN ('general', 'security', 'notification', 'community', 'storage', 'backup', 'maintenance')),
  is_public boolean NOT NULL DEFAULT false,
  updated_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view public settings" ON system_settings
  FOR SELECT USING (is_public = true);
CREATE POLICY "Admins can manage all settings" ON system_settings
  FOR ALL USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- Insert default system settings
INSERT INTO system_settings (key, value, description, category, is_public) VALUES
  ('app_version', '"1.0.0"'::jsonb, 'Current app version', 'general', true),
  ('maintenance_mode', 'false'::jsonb, 'Global maintenance mode', 'maintenance', true),
  ('max_upload_size_mb', '10'::jsonb, 'Max file upload size in MB', 'storage', true),
  ('community_enabled', 'false'::jsonb, 'Community features enabled', 'community', true),
  ('registration_enabled', 'true'::jsonb, 'User registration enabled', 'general', true),
  ('min_password_length', '8'::jsonb, 'Minimum password length', 'security', false),
  ('max_login_attempts', '5'::jsonb, 'Max login attempts before lock', 'security', false),
  ('auto_backup_enabled', 'true'::jsonb, 'System auto backup', 'backup', false);

-- 5. System Metrics (Performans metrikleri)
CREATE TABLE system_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_type text NOT NULL CHECK (metric_type IN ('cpu', 'memory', 'disk', 'network', 'database', 'api', 'storage', 'custom')),
  metric_name text NOT NULL,
  value double precision NOT NULL,
  unit text,
  avg_response_time_ms double precision,
  error_rate double precision,
  active_connections int,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_system_metrics_type ON system_metrics(metric_type);
CREATE INDEX idx_system_metrics_date ON system_metrics(created_at);

ALTER TABLE system_metrics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can view metrics" ON system_metrics
  FOR SELECT USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- 6. System Status (Sistem sağlık durumu)
CREATE TABLE system_status (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service text NOT NULL UNIQUE CHECK (service IN ('api', 'database', 'storage', 'auth', 'realtime', 'edge_functions', 'overall')),
  status text NOT NULL DEFAULT 'operational' CHECK (status IN ('operational', 'degraded', 'partial_outage', 'major_outage', 'maintenance')),
  uptime text,
  last_check_at timestamptz DEFAULT now(),
  details jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE system_status ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can manage status" ON system_status
  FOR ALL USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- Insert default status
INSERT INTO system_status (service, status, uptime) VALUES
  ('overall', 'operational', '100%'),
  ('api', 'operational', '100%'),
  ('database', 'operational', '100%'),
  ('storage', 'operational', '100%'),
  ('auth', 'operational', '100%'),
  ('realtime', 'operational', '100%'),
  ('edge_functions', 'operational', '100%');

-- 7. System Alerts (Sistem uyarıları)
CREATE TABLE system_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  message text NOT NULL,
  severity text NOT NULL DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'error', 'critical')),
  alert_type text NOT NULL DEFAULT 'system' CHECK (alert_type IN ('system', 'security', 'performance', 'storage', 'user', 'maintenance')),
  is_active boolean NOT NULL DEFAULT true,
  is_acknowledged boolean NOT NULL DEFAULT false,
  acknowledged_by uuid REFERENCES auth.users(id),
  acknowledged_at timestamptz,
  auto_resolve boolean NOT NULL DEFAULT false,
  expires_at timestamptz,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_system_alerts_active ON system_alerts(is_active, severity);
CREATE INDEX idx_system_alerts_type ON system_alerts(alert_type);

ALTER TABLE system_alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can manage alerts" ON system_alerts
  FOR ALL USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- 8. Error Logs (Uygulama hata kayıtları)
CREATE TABLE error_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  error_type text NOT NULL CHECK (error_type IN ('client', 'server', 'database', 'network', 'auth', 'storage', 'unknown')),
  severity text NOT NULL DEFAULT 'error' CHECK (severity IN ('debug', 'info', 'warning', 'error', 'fatal')),
  message text NOT NULL,
  stack_trace text,
  context jsonb DEFAULT '{}'::jsonb,
  platform text,
  app_version text,
  device_info text,
  url text,
  occurrence_count int NOT NULL DEFAULT 1,
  first_seen_at timestamptz DEFAULT now(),
  last_seen_at timestamptz DEFAULT now(),
  is_resolved boolean NOT NULL DEFAULT false,
  resolved_by uuid REFERENCES auth.users(id),
  resolved_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_error_logs_type ON error_logs(error_type);
CREATE INDEX idx_error_logs_severity ON error_logs(severity);
CREATE INDEX idx_error_logs_date ON error_logs(created_at);
CREATE INDEX idx_error_logs_resolved ON error_logs(is_resolved);

ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can manage error logs" ON error_logs
  FOR ALL USING (auth.uid() IN (SELECT user_id FROM admin_users));
CREATE POLICY "System can insert errors" ON error_logs
  FOR INSERT WITH CHECK (true);
;
