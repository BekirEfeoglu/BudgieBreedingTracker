-- Chicks tablosunun realtime sorununu çöz
-- Önce mevcut durumu kontrol et
SELECT 
  'Current chicks table structure:' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'chicks'
ORDER BY ordinal_position;

-- Publication durumunu kontrol et
SELECT 
  'Current publication status:' as info,
  pubname,
  tablename,
  schemaname
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' AND tablename = 'chicks';

-- Chicks tablosunu publication'dan çıkar ve tekrar ekle
DO $$
BEGIN
  -- Önce çıkar
  ALTER PUBLICATION supabase_realtime DROP TABLE public.chicks;
  RAISE NOTICE 'Removed chicks table from publication';
  
  -- Sonra tekrar ekle
  ALTER PUBLICATION supabase_realtime ADD TABLE public.chicks;
  RAISE NOTICE 'Added chicks table back to publication';
END
$$;

-- Trigger'ları yeniden oluştur
DROP TRIGGER IF EXISTS handle_chicks_updated_at ON public.chicks;
CREATE TRIGGER handle_chicks_updated_at
  BEFORE UPDATE ON public.chicks
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Realtime için özel trigger oluştur (eğer yoksa)
CREATE OR REPLACE FUNCTION public.handle_chicks_realtime()
RETURNS TRIGGER AS $$
BEGIN
  -- updated_at alanını güncelle
  NEW.updated_at = NOW();
  
  -- Realtime için gerekli alanları kontrol et
  IF NEW.user_id IS NULL THEN
    NEW.user_id = (SELECT auth.uid());
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger'ı ekle
DROP TRIGGER IF EXISTS chicks_realtime_trigger ON public.chicks;
CREATE TRIGGER chicks_realtime_trigger
  BEFORE INSERT OR UPDATE ON public.chicks
  FOR EACH ROW EXECUTE FUNCTION public.handle_chicks_realtime();

-- Policy'yi optimize et
DROP POLICY IF EXISTS "Users can manage their own chicks" ON public.chicks;
CREATE POLICY "Users can manage their own chicks" ON public.chicks 
FOR ALL USING ((select auth.uid()) = user_id);

-- Tablo istatistiklerini güncelle
ANALYZE public.chicks;

-- Son durumu kontrol et
SELECT 
  'Final publication status:' as info,
  pubname,
  tablename,
  schemaname
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' AND tablename = 'chicks';

-- Trigger'ları listele
SELECT 
  'Active triggers:' as info,
  trigger_name,
  event_manipulation,
  action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'chicks'
ORDER BY trigger_name; 