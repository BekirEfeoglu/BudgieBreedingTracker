-- Supabase Realtime Publication'larını düzelt
-- Önce mevcut publication'ı kontrol et ve gerekirse oluştur
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    CREATE PUBLICATION supabase_realtime FOR ALL TABLES;
    RAISE NOTICE 'Created supabase_realtime publication';
  ELSE
    RAISE NOTICE 'supabase_realtime publication already exists';
  END IF;
END
$$;

-- Tabloları publication'a ekle (eğer zaten ekli değilse)
DO $$
BEGIN
  -- Birds tablosu
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'birds'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.birds;
    RAISE NOTICE 'Added birds table to supabase_realtime publication';
  ELSE
    RAISE NOTICE 'birds table already in supabase_realtime publication';
  END IF;

  -- Chicks tablosu
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'chicks'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chicks;
    RAISE NOTICE 'Added chicks table to supabase_realtime publication';
  ELSE
    RAISE NOTICE 'chicks table already in supabase_realtime publication';
  END IF;

  -- Eggs tablosu
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'eggs'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.eggs;
    RAISE NOTICE 'Added eggs table to supabase_realtime publication';
  ELSE
    RAISE NOTICE 'eggs table already in supabase_realtime publication';
  END IF;

  -- Incubations tablosu (eğer varsa)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'incubations') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'incubations'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.incubations;
      RAISE NOTICE 'Added incubations table to supabase_realtime publication';
    ELSE
      RAISE NOTICE 'incubations table already in supabase_realtime publication';
    END IF;
  END IF;
END
$$;

-- Realtime trigger'larını yeniden oluştur (eğer eksikse)
DO $$
BEGIN
  -- Birds updated_at trigger
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.triggers 
    WHERE trigger_name = 'handle_birds_updated_at'
  ) THEN
    CREATE TRIGGER handle_birds_updated_at
      BEFORE UPDATE ON public.birds
      FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
    RAISE NOTICE 'Created birds updated_at trigger';
  END IF;

  -- Chicks updated_at trigger
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.triggers 
    WHERE trigger_name = 'handle_chicks_updated_at'
  ) THEN
    CREATE TRIGGER handle_chicks_updated_at
      BEFORE UPDATE ON public.chicks
      FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
    RAISE NOTICE 'Created chicks updated_at trigger';
  END IF;

  -- Eggs updated_at trigger
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.triggers 
    WHERE trigger_name = 'handle_eggs_updated_at'
  ) THEN
    CREATE TRIGGER handle_eggs_updated_at
      BEFORE UPDATE ON public.eggs
      FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
    RAISE NOTICE 'Created eggs updated_at trigger';
  END IF;
END
$$;

-- Publication durumunu kontrol et
SELECT 
  pubname,
  tablename,
  schemaname
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
ORDER BY tablename; 