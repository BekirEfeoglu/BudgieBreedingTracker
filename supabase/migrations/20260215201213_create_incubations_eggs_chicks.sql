
-- Incubations table (no is_deleted - uses BaseRemoteSourceNoSoftDelete)
CREATE TABLE incubations (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active',
  version INTEGER NOT NULL DEFAULT 1,
  clutch_id UUID,
  breeding_pair_id UUID REFERENCES breeding_pairs(id) ON DELETE SET NULL,
  notes TEXT,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  expected_hatch_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_incubations_user_id ON incubations(user_id);
CREATE INDEX idx_incubations_breeding_pair_id ON incubations(breeding_pair_id);

CREATE TRIGGER update_incubations_updated_at
  BEFORE UPDATE ON incubations
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- Eggs table
CREATE TABLE eggs (
  id UUID PRIMARY KEY,
  lay_date TIMESTAMPTZ NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'laid',
  clutch_id UUID,
  incubation_id UUID REFERENCES incubations(id) ON DELETE SET NULL,
  egg_number INTEGER,
  notes TEXT,
  photo_url TEXT,
  hatch_date TIMESTAMPTZ,
  fertile_check_date TIMESTAMPTZ,
  discard_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_eggs_user_id ON eggs(user_id);
CREATE INDEX idx_eggs_incubation_id ON eggs(incubation_id);

CREATE TRIGGER update_eggs_updated_at
  BEFORE UPDATE ON eggs
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- Chicks table
CREATE TABLE chicks (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  gender TEXT NOT NULL DEFAULT 'unknown',
  health_status TEXT NOT NULL DEFAULT 'healthy',
  clutch_id UUID,
  egg_id UUID REFERENCES eggs(id) ON DELETE SET NULL,
  bird_id UUID REFERENCES birds(id) ON DELETE SET NULL,
  name TEXT,
  ring_number TEXT,
  notes TEXT,
  photo_url TEXT,
  hatch_weight DOUBLE PRECISION,
  hatch_date TIMESTAMPTZ,
  wean_date TIMESTAMPTZ,
  death_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_chicks_user_id ON chicks(user_id);
CREATE INDEX idx_chicks_egg_id ON chicks(egg_id);

CREATE TRIGGER update_chicks_updated_at
  BEFORE UPDATE ON chicks
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();
;
