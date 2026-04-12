
-- Health records table
CREATE TABLE health_records (
  id UUID PRIMARY KEY,
  date TIMESTAMPTZ NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bird_id UUID REFERENCES birds(id) ON DELETE SET NULL,
  description TEXT,
  treatment TEXT,
  veterinarian TEXT,
  notes TEXT,
  weight DOUBLE PRECISION,
  cost DOUBLE PRECISION,
  follow_up_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_health_records_user_id ON health_records(user_id);
CREATE INDEX idx_health_records_bird_id ON health_records(bird_id);

CREATE TRIGGER update_health_records_updated_at
  BEFORE UPDATE ON health_records
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- Growth measurements table (no is_deleted - uses BaseRemoteSourceNoSoftDelete)
CREATE TABLE growth_measurements (
  id UUID PRIMARY KEY,
  chick_id UUID NOT NULL REFERENCES chicks(id) ON DELETE CASCADE,
  weight DOUBLE PRECISION NOT NULL,
  measurement_date TIMESTAMPTZ NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  height DOUBLE PRECISION,
  wing_length DOUBLE PRECISION,
  tail_length DOUBLE PRECISION,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_growth_measurements_chick_id ON growth_measurements(chick_id);
CREATE INDEX idx_growth_measurements_user_id ON growth_measurements(user_id);

CREATE TRIGGER update_growth_measurements_updated_at
  BEFORE UPDATE ON growth_measurements
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- Events table
CREATE TABLE events (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  event_date TIMESTAMPTZ NOT NULL,
  type TEXT NOT NULL DEFAULT 'custom',
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active',
  description TEXT,
  bird_id UUID REFERENCES birds(id) ON DELETE SET NULL,
  breeding_pair_id UUID REFERENCES breeding_pairs(id) ON DELETE SET NULL,
  notes TEXT,
  end_date TIMESTAMPTZ,
  reminder_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_bird_id ON events(bird_id);

CREATE TRIGGER update_events_updated_at
  BEFORE UPDATE ON events
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();
;
