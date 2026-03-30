
-- =============================================
-- BATCH 6: Arşivleme (Cold Storage) - 8 tablo
-- =============================================

-- 1. Archived Birds
CREATE TABLE archived_birds (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  original_data jsonb NOT NULL,
  archived_reason text NOT NULL DEFAULT 'manual' CHECK (archived_reason IN ('manual', 'auto', 'deceased', 'sold', 'inactive')),
  archived_at timestamptz DEFAULT now(),
  archived_by uuid REFERENCES auth.users(id),
  restore_until timestamptz,
  created_at timestamptz
);

CREATE INDEX idx_archived_birds_user ON archived_birds(user_id);
CREATE INDEX idx_archived_birds_date ON archived_birds(archived_at);

ALTER TABLE archived_birds ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own archived birds" ON archived_birds
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 2. Archived Breeding Pairs
CREATE TABLE archived_breeding_pairs (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  original_data jsonb NOT NULL,
  archived_reason text NOT NULL DEFAULT 'manual',
  archived_at timestamptz DEFAULT now(),
  archived_by uuid REFERENCES auth.users(id),
  created_at timestamptz
);

CREATE INDEX idx_archived_pairs_user ON archived_breeding_pairs(user_id);

ALTER TABLE archived_breeding_pairs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own archived pairs" ON archived_breeding_pairs
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 3. Archived Clutches
CREATE TABLE archived_clutches (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  original_data jsonb NOT NULL,
  archived_reason text NOT NULL DEFAULT 'manual',
  archived_at timestamptz DEFAULT now(),
  archived_by uuid REFERENCES auth.users(id),
  created_at timestamptz
);

CREATE INDEX idx_archived_clutches_user ON archived_clutches(user_id);

ALTER TABLE archived_clutches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own archived clutches" ON archived_clutches
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 4. Archived Eggs
CREATE TABLE archived_eggs (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  original_data jsonb NOT NULL,
  archived_reason text NOT NULL DEFAULT 'manual',
  archived_at timestamptz DEFAULT now(),
  archived_by uuid REFERENCES auth.users(id),
  created_at timestamptz
);

CREATE INDEX idx_archived_eggs_user ON archived_eggs(user_id);

ALTER TABLE archived_eggs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own archived eggs" ON archived_eggs
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 5. Archived Chicks
CREATE TABLE archived_chicks (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  original_data jsonb NOT NULL,
  archived_reason text NOT NULL DEFAULT 'manual',
  archived_at timestamptz DEFAULT now(),
  archived_by uuid REFERENCES auth.users(id),
  created_at timestamptz
);

CREATE INDEX idx_archived_chicks_user ON archived_chicks(user_id);

ALTER TABLE archived_chicks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own archived chicks" ON archived_chicks
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 6. Archive Jobs (Arşivleme işlemleri)
CREATE TABLE archive_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  job_type text NOT NULL CHECK (job_type IN ('archive', 'restore', 'auto_archive', 'bulk_archive')),
  entity_type text NOT NULL CHECK (entity_type IN ('bird', 'breeding_pair', 'clutch', 'egg', 'chick', 'all')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  total_items int NOT NULL DEFAULT 0,
  processed_items int NOT NULL DEFAULT 0,
  error_message text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_archive_jobs_user ON archive_jobs(user_id);
CREATE INDEX idx_archive_jobs_status ON archive_jobs(status);

ALTER TABLE archive_jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own archive jobs" ON archive_jobs
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 7. Archive Settings (Otomatik arşivleme kuralları)
CREATE TABLE archive_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  auto_archive_enabled boolean NOT NULL DEFAULT false,
  archive_deceased_after_days int NOT NULL DEFAULT 90,
  archive_sold_after_days int NOT NULL DEFAULT 60,
  archive_completed_breeding_after_days int NOT NULL DEFAULT 180,
  archive_hatched_eggs_after_days int NOT NULL DEFAULT 90,
  retain_archived_for_days int,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE archive_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own archive settings" ON archive_settings
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 8. Egg Archives (Eski/Alternatif arşiv)
CREATE TABLE egg_archives (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  original_egg_id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  egg_data jsonb NOT NULL,
  archive_reason text,
  archived_at timestamptz DEFAULT now()
);

CREATE INDEX idx_egg_archives_user ON egg_archives(user_id);

ALTER TABLE egg_archives ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own egg archives" ON egg_archives
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
;
