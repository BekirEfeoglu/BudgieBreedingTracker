
-- Notifications table
CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  read BOOLEAN NOT NULL DEFAULT FALSE,
  type TEXT NOT NULL DEFAULT 'custom',
  priority TEXT NOT NULL DEFAULT 'normal',
  body TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  reference_id TEXT,
  reference_type TEXT,
  scheduled_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);

CREATE TRIGGER update_notifications_updated_at
  BEFORE UPDATE ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- Notification settings table
CREATE TABLE notification_settings (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  language TEXT NOT NULL DEFAULT 'tr',
  sound_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  vibration_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  egg_turning_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  temperature_alert_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  humidity_alert_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  feeding_reminder_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  incubation_reminder_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  health_check_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  temperature_min DOUBLE PRECISION NOT NULL DEFAULT 37.0,
  temperature_max DOUBLE PRECISION NOT NULL DEFAULT 38.0,
  humidity_min DOUBLE PRECISION NOT NULL DEFAULT 55.0,
  humidity_max DOUBLE PRECISION NOT NULL DEFAULT 65.0,
  egg_turning_interval_minutes INTEGER NOT NULL DEFAULT 480,
  feeding_reminder_interval_minutes INTEGER NOT NULL DEFAULT 1440,
  temperature_check_interval_minutes INTEGER NOT NULL DEFAULT 60,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notification_settings_user_id ON notification_settings(user_id);
CREATE UNIQUE INDEX idx_notification_settings_user_unique ON notification_settings(user_id);

CREATE TRIGGER update_notification_settings_updated_at
  BEFORE UPDATE ON notification_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();
;
