
-- =============================================
-- BATCH 7: Güvenlik & Gizlilik
-- =============================================

-- 1. Privacy Settings (Veri paylaşım kuralları)
CREATE TABLE privacy_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  profile_visibility text NOT NULL DEFAULT 'public' CHECK (profile_visibility IN ('public', 'registered', 'private')),
  show_bird_count boolean NOT NULL DEFAULT true,
  show_breeding_stats boolean NOT NULL DEFAULT true,
  show_location boolean NOT NULL DEFAULT false,
  allow_messages boolean NOT NULL DEFAULT true,
  allow_community_mentions boolean NOT NULL DEFAULT true,
  data_export_allowed boolean NOT NULL DEFAULT true,
  third_party_sharing boolean NOT NULL DEFAULT false,
  search_indexing boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE privacy_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own privacy" ON privacy_settings
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 2. Privacy Audit Logs (Erişim ve paylaşım logları)
CREATE TABLE privacy_audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action text NOT NULL CHECK (action IN ('data_export', 'data_delete', 'profile_view', 'data_share', 'consent_change', 'settings_change')),
  entity_type text,
  entity_id uuid,
  details jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_privacy_audit_user ON privacy_audit_logs(user_id);
CREATE INDEX idx_privacy_audit_action ON privacy_audit_logs(action);
CREATE INDEX idx_privacy_audit_date ON privacy_audit_logs(created_at);

ALTER TABLE privacy_audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own privacy logs" ON privacy_audit_logs
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System can insert logs" ON privacy_audit_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins can view all privacy logs" ON privacy_audit_logs
  FOR SELECT USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- 3. Security Events (Güvenlik ihlalleri)
CREATE TABLE security_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  event_type text NOT NULL CHECK (event_type IN (
    'login_success', 'login_failure', 'logout', 'password_change',
    'email_change', 'mfa_enabled', 'mfa_disabled', 'account_locked',
    'account_unlocked', 'suspicious_activity', 'brute_force_attempt',
    'token_refresh', 'session_expired', 'api_key_created', 'api_key_revoked'
  )),
  severity text NOT NULL DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical')),
  ip_address inet,
  user_agent text,
  location text,
  details jsonb DEFAULT '{}'::jsonb,
  is_resolved boolean NOT NULL DEFAULT false,
  resolved_by uuid REFERENCES auth.users(id),
  resolved_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_security_events_user ON security_events(user_id);
CREATE INDEX idx_security_events_type ON security_events(event_type);
CREATE INDEX idx_security_events_severity ON security_events(severity);
CREATE INDEX idx_security_events_date ON security_events(created_at);

ALTER TABLE security_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own security events" ON security_events
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all security events" ON security_events
  FOR SELECT USING (auth.uid() IN (SELECT user_id FROM admin_users));
CREATE POLICY "System can insert events" ON security_events
  FOR INSERT WITH CHECK (true);
;
