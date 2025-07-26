-- Eggs tablosu database schema düzeltmesi
-- lay_date alanını kaldır ve hatch_date'i yumurtlama tarihi olarak kullan

-- 1. Mevcut durumu kontrol et
SELECT '=== MEVCUT DURUM ===' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'eggs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. lay_date alanını kaldır (eğer varsa)
ALTER TABLE public.eggs DROP COLUMN IF EXISTS lay_date;

-- 3. hatch_date alanını NOT NULL yap (eğer değilse)
ALTER TABLE public.eggs ALTER COLUMN hatch_date SET NOT NULL;

-- 4. hatch_date için default değer ekle (eğer yoksa)
ALTER TABLE public.eggs ALTER COLUMN hatch_date SET DEFAULT CURRENT_DATE;

-- 5. Güncellenmiş durumu kontrol et
SELECT '=== GÜNCELLENMİŞ DURUM ===' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'eggs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 6. İndeksleri güncelle
DROP INDEX IF EXISTS idx_eggs_lay_date;
CREATE INDEX IF NOT EXISTS idx_eggs_hatch_date ON public.eggs(hatch_date);
CREATE INDEX IF NOT EXISTS idx_eggs_incubation_id ON public.eggs(incubation_id);
CREATE INDEX IF NOT EXISTS idx_eggs_user_id ON public.eggs(user_id);
CREATE INDEX IF NOT EXISTS idx_eggs_egg_number ON public.eggs(egg_number);

-- 7. RLS politikalarını kontrol et
SELECT '=== RLS POLİTİKALARI ===' as info;
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'eggs';

-- 8. Realtime durumunu kontrol et
SELECT '=== REALTIME DURUMU ===' as info;
SELECT 
    schemaname,
    tablename,
    pubname
FROM pg_publication_tables 
WHERE tablename = 'eggs';

-- 9. Eğer realtime yoksa ekle
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.eggs; 