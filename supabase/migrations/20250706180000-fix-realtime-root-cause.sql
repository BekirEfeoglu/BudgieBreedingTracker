-- Realtime Sorununun Kök Nedenini Çöz
-- Bu migration tüm uyumsuzlukları giderir

-- 1. ÖNCE MEVCUT DURUMU ANALİZ ET
SELECT '=== ANALYZING CURRENT STATE ===' as step;

-- Chicks tablosunun mevcut yapısını kontrol et
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'chicks' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. TYPES DOSYASINDAKİ UYUMSUZLUKLARI DÜZELT
-- Eksik alanları ekle (types dosyasında var ama migration'da yok)

-- clutch_id alanını ekle (eğer yoksa)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chicks' AND column_name = 'clutch_id'
  ) THEN
    ALTER TABLE public.chicks ADD COLUMN clutch_id UUID REFERENCES public.clutches(id) ON DELETE SET NULL;
    RAISE NOTICE 'Added clutch_id column to chicks table';
  ELSE
    RAISE NOTICE 'clutch_id column already exists in chicks table';
  END IF;
END
$$;

-- 3. FOREIGN KEY İLİŞKİLERİNİ DÜZELT
-- Eksik foreign key'leri ekle
DO $$
BEGIN
  -- chicks_clutch_id_fkey
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'chicks_clutch_id_fkey' AND table_name = 'chicks'
  ) THEN
    ALTER TABLE public.chicks ADD CONSTRAINT chicks_clutch_id_fkey 
    FOREIGN KEY (clutch_id) REFERENCES public.clutches(id) ON DELETE SET NULL;
    RAISE NOTICE 'Added chicks_clutch_id_fkey constraint';
  END IF;
  
  -- chicks_egg_id_fkey
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'chicks_egg_id_fkey' AND table_name = 'chicks'
  ) THEN
    ALTER TABLE public.chicks ADD CONSTRAINT chicks_egg_id_fkey 
    FOREIGN KEY (egg_id) REFERENCES public.eggs(id) ON DELETE SET NULL;
    RAISE NOTICE 'Added chicks_egg_id_fkey constraint';
  END IF;
  
  -- chicks_father_id_fkey
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'chicks_father_id_fkey' AND table_name = 'chicks'
  ) THEN
    ALTER TABLE public.chicks ADD CONSTRAINT chicks_father_id_fkey 
    FOREIGN KEY (father_id) REFERENCES public.birds(id) ON DELETE SET NULL;
    RAISE NOTICE 'Added chicks_father_id_fkey constraint';
  END IF;
  
  -- chicks_mother_id_fkey
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'chicks_mother_id_fkey' AND table_name = 'chicks'
  ) THEN
    ALTER TABLE public.chicks ADD CONSTRAINT chicks_mother_id_fkey 
    FOREIGN KEY (mother_id) REFERENCES public.birds(id) ON DELETE SET NULL;
    RAISE NOTICE 'Added chicks_mother_id_fkey constraint';
  END IF;
  
  -- chicks_incubation_id_fkey
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'chicks_incubation_id_fkey' AND table_name = 'chicks'
  ) THEN
    ALTER TABLE public.chicks ADD CONSTRAINT chicks_incubation_id_fkey 
    FOREIGN KEY (incubation_id) REFERENCES public.incubations(id) ON DELETE CASCADE;
    RAISE NOTICE 'Added chicks_incubation_id_fkey constraint';
  END IF;
END
$$;

-- 4. INDEX'LERİ DÜZELT
-- Eksik index'leri ekle
CREATE INDEX IF NOT EXISTS idx_chicks_clutch_id ON public.chicks(clutch_id);
CREATE INDEX IF NOT EXISTS idx_chicks_egg_id ON public.chicks(egg_id);
CREATE INDEX IF NOT EXISTS idx_chicks_father_id ON public.chicks(father_id);
CREATE INDEX IF NOT EXISTS idx_chicks_mother_id ON public.chicks(mother_id);

-- 5. PUBLICATION'LARI TEMİZLE VE YENİDEN AYARLA
-- Önce tüm tabloları publication'dan çıkar
DO $$
DECLARE
  table_record RECORD;
BEGIN
  FOR table_record IN 
    SELECT tablename FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime'
  LOOP
    EXECUTE format('ALTER PUBLICATION supabase_realtime DROP TABLE public.%I', table_record.tablename);
    RAISE NOTICE 'Removed % from publication', table_record.tablename;
  END LOOP;
END
$$;

-- Sonra tabloları tekrar ekle
ALTER PUBLICATION supabase_realtime ADD TABLE public.birds;
ALTER PUBLICATION supabase_realtime ADD TABLE public.incubations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chicks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.eggs;
ALTER PUBLICATION supabase_realtime ADD TABLE public.clutches;

-- 6. TRIGGER'LARI YENİDEN OLUŞTUR
-- Önce eski trigger'ları sil
DROP TRIGGER IF EXISTS handle_chicks_updated_at ON public.chicks;
DROP TRIGGER IF EXISTS chicks_realtime_trigger ON public.chicks;

-- Sonra yeni trigger'ları oluştur
CREATE TRIGGER handle_chicks_updated_at
  BEFORE UPDATE ON public.chicks
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 7. POLICY'LERİ OPTİMİZE ET
-- Önce eski policy'leri sil
DROP POLICY IF EXISTS "Users can manage their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can create their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can view their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can update their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can delete their own chicks" ON public.chicks;

-- Tek bir optimize policy oluştur
CREATE POLICY "Users can manage their own chicks" ON public.chicks 
FOR ALL USING ((select auth.uid()) = user_id);

-- 8. TABLO İSTATİSTİKLERİNİ GÜNCELLE
ANALYZE public.chicks;
ANALYZE public.birds;
ANALYZE public.incubations;
ANALYZE public.eggs;
ANALYZE public.clutches;

-- 9. SON DURUMU KONTROL ET
SELECT '=== FINAL STATE CHECK ===' as step;

-- Publication durumu
SELECT 
  'Publication Status:' as info,
  pubname,
  tablename
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;

-- Chicks tablosu yapısı
SELECT 
  'Chicks Table Structure:' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'chicks' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Foreign key'ler
SELECT 
  'Foreign Keys:' as info,
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'chicks'
ORDER BY tc.constraint_name; 