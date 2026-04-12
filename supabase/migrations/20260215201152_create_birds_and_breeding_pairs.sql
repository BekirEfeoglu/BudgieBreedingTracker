
-- Birds table
CREATE TABLE birds (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  gender TEXT NOT NULL DEFAULT 'unknown',
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'alive',
  species TEXT NOT NULL DEFAULT 'budgie',
  ring_number TEXT,
  photo_url TEXT,
  father_id UUID REFERENCES birds(id) ON DELETE SET NULL,
  mother_id UUID REFERENCES birds(id) ON DELETE SET NULL,
  cage_number TEXT,
  notes TEXT,
  birth_date TIMESTAMPTZ,
  death_date TIMESTAMPTZ,
  sold_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_birds_user_id ON birds(user_id);
CREATE INDEX idx_birds_father_id ON birds(father_id);
CREATE INDEX idx_birds_mother_id ON birds(mother_id);

CREATE TRIGGER update_birds_updated_at
  BEFORE UPDATE ON birds
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- Breeding pairs table
CREATE TABLE breeding_pairs (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active',
  male_id UUID REFERENCES birds(id) ON DELETE SET NULL,
  female_id UUID REFERENCES birds(id) ON DELETE SET NULL,
  cage_number TEXT,
  notes TEXT,
  pairing_date TIMESTAMPTZ,
  separation_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_breeding_pairs_user_id ON breeding_pairs(user_id);
CREATE INDEX idx_breeding_pairs_male_id ON breeding_pairs(male_id);
CREATE INDEX idx_breeding_pairs_female_id ON breeding_pairs(female_id);

CREATE TRIGGER update_breeding_pairs_updated_at
  BEFORE UPDATE ON breeding_pairs
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();
;
