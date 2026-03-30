
-- Eksik ayarları ekle (value jsonb tipinde olduğu için cast gerekli)

-- 1) registration_open (kod bunu bekliyor)
INSERT INTO system_settings (key, value, description, category, is_public)
VALUES ('registration_open', 'true'::jsonb, 'User registration open', 'security', false)
ON CONFLICT (key) DO NOTHING;

-- 2) email_verification_required
INSERT INTO system_settings (key, value, description, category, is_public)
VALUES ('email_verification_required', 'true'::jsonb, 'Email verification required for registration', 'security', false)
ON CONFLICT (key) DO NOTHING;

-- 3) premium_enabled
INSERT INTO system_settings (key, value, description, category, is_public)
VALUES ('premium_enabled', 'true'::jsonb, 'Premium features enabled', 'general', false)
ON CONFLICT (key) DO NOTHING;

-- 4) rate_limiting_enabled
INSERT INTO system_settings (key, value, description, category, is_public)
VALUES ('rate_limiting_enabled', 'true'::jsonb, 'API rate limiting enabled', 'security', false)
ON CONFLICT (key) DO NOTHING;
;
