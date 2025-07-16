-- Birds tablosu
CREATE TABLE IF NOT EXISTS public.birds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  gender TEXT CHECK (gender IN ('male', 'female', 'unknown')) NOT NULL DEFAULT 'unknown',
  color TEXT,
  birth_date DATE,
  ring_number TEXT,
  photo_url TEXT,
  health_notes TEXT,
  mother_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  father_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Incubations tablosu
CREATE TABLE IF NOT EXISTS public.incubations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  female_bird_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  male_bird_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Chicks tablosu
CREATE TABLE IF NOT EXISTS public.chicks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  gender TEXT CHECK (gender IN ('male', 'female', 'unknown')) NOT NULL DEFAULT 'unknown',
  color TEXT,
  hatch_date DATE NOT NULL,
  ring_number TEXT,
  photo_url TEXT,
  health_notes TEXT,
  mother_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  father_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  incubation_id UUID NOT NULL REFERENCES public.incubations(id) ON DELETE CASCADE,
  egg_id UUID REFERENCES public.eggs(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Eggs tablosu
CREATE TABLE IF NOT EXISTS public.eggs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  incubation_id UUID NOT NULL REFERENCES public.incubations(id) ON DELETE CASCADE,
  lay_date DATE NOT NULL,
  status TEXT CHECK (status IN ('laid', 'fertile', 'hatched', 'infertile')) NOT NULL DEFAULT 'laid',
  hatch_date DATE,
  notes TEXT,
  chick_id UUID REFERENCES public.chicks(id) ON DELETE SET NULL,
  number INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Indexler
CREATE INDEX IF NOT EXISTS idx_birds_user_id ON public.birds(user_id);
CREATE INDEX IF NOT EXISTS idx_incubations_user_id ON public.incubations(user_id);
CREATE INDEX IF NOT EXISTS idx_chicks_user_id ON public.chicks(user_id);
CREATE INDEX IF NOT EXISTS idx_chicks_incubation_id ON public.chicks(incubation_id);
CREATE INDEX IF NOT EXISTS idx_eggs_user_id ON public.eggs(user_id);
CREATE INDEX IF NOT EXISTS idx_eggs_incubation_id ON public.eggs(incubation_id);

-- RLS ve Policy
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own birds" ON public.birds FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own incubations" ON public.incubations FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own chicks" ON public.chicks FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own eggs" ON public.eggs FOR ALL USING (auth.uid() = user_id);

-- updated_at trigger fonksiyonu (daha önce migrationda yoksa ekleyin)
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER handle_birds_updated_at
  BEFORE UPDATE ON public.birds
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER handle_incubations_updated_at
  BEFORE UPDATE ON public.incubations
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER handle_chicks_updated_at
  BEFORE UPDATE ON public.chicks
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER handle_eggs_updated_at
  BEFORE UPDATE ON public.eggs
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Supabase Realtime Publication'ları
-- Önce publication'ı oluştur (eğer yoksa)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    CREATE PUBLICATION supabase_realtime FOR ALL TABLES;
  END IF;
END
$$;

-- Tabloları publication'a ekle
ALTER PUBLICATION supabase_realtime ADD TABLE public.birds;
ALTER PUBLICATION supabase_realtime ADD TABLE public.incubations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chicks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.eggs; 