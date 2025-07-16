-- Incubations tablosunu düzelt
-- Önce mevcut tabloyu kontrol et
DO $$
BEGIN
  -- Incubations tablosu yoksa oluştur
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'incubations') THEN
    CREATE TABLE public.incubations (
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
    RAISE NOTICE 'Created incubations table';
  ELSE
    -- Tablo varsa user_id alanını ekle (eğer yoksa)
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'incubations' AND column_name = 'user_id'
    ) THEN
      ALTER TABLE public.incubations ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
      RAISE NOTICE 'Added user_id column to incubations table';
    END IF;
    
    -- Eksik alanları ekle
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'incubations' AND column_name = 'female_bird_id'
    ) THEN
      ALTER TABLE public.incubations ADD COLUMN female_bird_id UUID REFERENCES public.birds(id) ON DELETE SET NULL;
      RAISE NOTICE 'Added female_bird_id column to incubations table';
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'incubations' AND column_name = 'male_bird_id'
    ) THEN
      ALTER TABLE public.incubations ADD COLUMN male_bird_id UUID REFERENCES public.birds(id) ON DELETE SET NULL;
      RAISE NOTICE 'Added male_bird_id column to incubations table';
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'incubations' AND column_name = 'notes'
    ) THEN
      ALTER TABLE public.incubations ADD COLUMN notes TEXT;
      RAISE NOTICE 'Added notes column to incubations table';
    END IF;
  END IF;
END
$$;

-- Index ekle
CREATE INDEX IF NOT EXISTS idx_incubations_user_id ON public.incubations(user_id);

-- RLS etkinleştir
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;

-- Policy ekle
DROP POLICY IF EXISTS "Users can manage their own incubations" ON public.incubations;
CREATE POLICY "Users can manage their own incubations" ON public.incubations FOR ALL USING (auth.uid() = user_id);

-- Trigger ekle
DROP TRIGGER IF EXISTS handle_incubations_updated_at ON public.incubations;
CREATE TRIGGER handle_incubations_updated_at
  BEFORE UPDATE ON public.incubations
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Publication'a ekle (güvenli şekilde)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'incubations'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.incubations;
    RAISE NOTICE 'Added incubations table to supabase_realtime publication';
  ELSE
    RAISE NOTICE 'incubations table already in supabase_realtime publication';
  END IF;
END
$$;

-- Tablo durumunu kontrol et
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'incubations'
ORDER BY ordinal_position; 