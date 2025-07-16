-- Incubations tablosunu basit şekilde düzelt
-- Sadece eksik olan kısımları ekle

-- user_id alanını ekle (eğer yoksa)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'incubations' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE public.incubations ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    RAISE NOTICE 'Added user_id column to incubations table';
  ELSE
    RAISE NOTICE 'user_id column already exists in incubations table';
  END IF;
END
$$;

-- Index ekle (eğer yoksa)
CREATE INDEX IF NOT EXISTS idx_incubations_user_id ON public.incubations(user_id);

-- RLS etkinleştir
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;

-- Policy ekle (eğer yoksa)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'incubations' AND policyname = 'Users can manage their own incubations'
  ) THEN
    CREATE POLICY "Users can manage their own incubations" ON public.incubations FOR ALL USING (auth.uid() = user_id);
    RAISE NOTICE 'Created incubations policy';
  ELSE
    RAISE NOTICE 'incubations policy already exists';
  END IF;
END
$$;

-- Tablo durumunu kontrol et
SELECT 
  'incubations' as table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'incubations'
ORDER BY ordinal_position; 