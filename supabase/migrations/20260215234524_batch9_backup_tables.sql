
-- =============================================
-- BATCH 9: Yedekleme (Backup)
-- =============================================

-- 1. Backup History (Alınan yedeklerin listesi)
CREATE TABLE backup_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  backup_type text NOT NULL DEFAULT 'manual' CHECK (backup_type IN ('manual', 'auto', 'scheduled', 'migration')),
  format text NOT NULL DEFAULT 'json' CHECK (format IN ('json', 'csv', 'sqlite', 'encrypted')),
  status text NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
  file_url text,
  file_size bigint,
  file_name text,
  included_tables jsonb DEFAULT '[]'::jsonb,
  record_count int NOT NULL DEFAULT 0,
  checksum text,
  encryption_key_hash text,
  error_message text,
  expires_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_backup_history_user ON backup_history(user_id);
CREATE INDEX idx_backup_history_date ON backup_history(created_at);

ALTER TABLE backup_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own backups" ON backup_history
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 2. Backup Jobs (Yedekleme işlem durumları)
CREATE TABLE backup_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  job_type text NOT NULL DEFAULT 'backup' CHECK (job_type IN ('backup', 'restore', 'export', 'import')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'queued', 'processing', 'completed', 'failed', 'cancelled')),
  progress int NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
  total_steps int NOT NULL DEFAULT 1,
  current_step int NOT NULL DEFAULT 0,
  current_step_name text,
  source_backup_id uuid REFERENCES backup_history(id),
  error_message text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_backup_jobs_user ON backup_jobs(user_id);
CREATE INDEX idx_backup_jobs_status ON backup_jobs(status);

ALTER TABLE backup_jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own backup jobs" ON backup_jobs
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 3. Backup Settings (Yedekleme yapılandırması)
CREATE TABLE backup_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  auto_backup_enabled boolean NOT NULL DEFAULT false,
  backup_frequency text NOT NULL DEFAULT 'weekly' CHECK (backup_frequency IN ('daily', 'weekly', 'monthly')),
  backup_time text NOT NULL DEFAULT '03:00',
  backup_day_of_week int CHECK (backup_day_of_week BETWEEN 0 AND 6),
  backup_day_of_month int CHECK (backup_day_of_month BETWEEN 1 AND 28),
  max_backups int NOT NULL DEFAULT 5,
  include_photos boolean NOT NULL DEFAULT false,
  encryption_enabled boolean NOT NULL DEFAULT false,
  backup_format text NOT NULL DEFAULT 'json' CHECK (backup_format IN ('json', 'csv', 'sqlite', 'encrypted')),
  last_backup_at timestamptz,
  next_backup_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE backup_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own backup settings" ON backup_settings
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 4. Config Backups (Ayar yedekleri)
CREATE TABLE config_backups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  config_type text NOT NULL CHECK (config_type IN ('preferences', 'notification_settings', 'privacy_settings', 'backup_settings', 'all')),
  config_data jsonb NOT NULL,
  description text,
  version int NOT NULL DEFAULT 1,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_config_backups_user ON config_backups(user_id);
CREATE INDEX idx_config_backups_type ON config_backups(config_type);

ALTER TABLE config_backups ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own config backups" ON config_backups
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
;
