
-- =============================================
-- BATCH 1: Temel Domain (clutches, nests, photos, deleted_eggs)
-- =============================================

-- 1. Clutches (Kuluçka kayıtları)
CREATE TABLE clutches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  breeding_pair_id uuid REFERENCES breeding_pairs(id) ON DELETE SET NULL,
  clutch_number int NOT NULL DEFAULT 1,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'failed', 'abandoned')),
  notes text,
  start_date timestamptz,
  end_date timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  is_deleted boolean NOT NULL DEFAULT false
);

CREATE INDEX idx_clutches_user_id ON clutches(user_id);
CREATE INDEX idx_clutches_breeding_pair_id ON clutches(breeding_pair_id);

ALTER TABLE clutches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own clutches" ON clutches
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Link eggs to clutches (add FK if not exists)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'eggs_clutch_id_fkey_v2' AND table_name = 'eggs'
  ) THEN
    ALTER TABLE eggs ADD CONSTRAINT eggs_clutch_id_fkey_v2
      FOREIGN KEY (clutch_id) REFERENCES clutches(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Link chicks to clutches
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'chicks_clutch_id_fkey_v2' AND table_name = 'chicks'
  ) THEN
    ALTER TABLE chicks ADD CONSTRAINT chicks_clutch_id_fkey_v2
      FOREIGN KEY (clutch_id) REFERENCES clutches(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Link incubations to clutches
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'incubations_clutch_id_fkey_v2' AND table_name = 'incubations'
  ) THEN
    ALTER TABLE incubations ADD CONSTRAINT incubations_clutch_id_fkey_v2
      FOREIGN KEY (clutch_id) REFERENCES clutches(id) ON DELETE SET NULL;
  END IF;
END $$;

-- 2. Nests (Yuva/kafes tanımları)
CREATE TABLE nests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  location text,
  nest_type text NOT NULL DEFAULT 'box' CHECK (nest_type IN ('box', 'natural', 'ceramic', 'wooden', 'other')),
  status text NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'occupied', 'maintenance', 'retired')),
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  is_deleted boolean NOT NULL DEFAULT false
);

CREATE INDEX idx_nests_user_id ON nests(user_id);

ALTER TABLE nests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own nests" ON nests
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 3. Photos (Fotoğraf galerisi)
CREATE TABLE photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  entity_type text NOT NULL CHECK (entity_type IN ('bird', 'egg', 'chick', 'breeding_pair', 'nest', 'health_record')),
  entity_id uuid NOT NULL,
  url text NOT NULL,
  thumbnail_url text,
  caption text,
  sort_order int NOT NULL DEFAULT 0,
  file_size bigint,
  mime_type text,
  width int,
  height int,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  is_deleted boolean NOT NULL DEFAULT false
);

CREATE INDEX idx_photos_user_id ON photos(user_id);
CREATE INDEX idx_photos_entity ON photos(entity_type, entity_id);

ALTER TABLE photos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own photos" ON photos
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 4. Deleted Eggs (Silinen yumurta kayıtları - audit log)
CREATE TABLE deleted_eggs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  original_egg_id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  clutch_id uuid,
  egg_number int,
  status text,
  lay_date timestamptz,
  deletion_reason text,
  deleted_by uuid REFERENCES auth.users(id),
  original_data jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_deleted_eggs_user_id ON deleted_eggs(user_id);

ALTER TABLE deleted_eggs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own deleted eggs" ON deleted_eggs
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own deleted eggs" ON deleted_eggs
  FOR INSERT WITH CHECK (auth.uid() = user_id);
;
