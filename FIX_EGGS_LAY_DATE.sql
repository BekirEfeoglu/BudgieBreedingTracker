-- Eggs tablosu lay_date sorunu düzeltme
-- Bu dosyayı Supabase Dashboard > SQL Editor'da çalıştırın

-- 1. Mevcut durumu kontrol et
SELECT '=== MEVCUT EGGS TABLOSU YAPISI ===' as info;
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

-- 5. start_date alanını ekle (eğer yoksa)
ALTER TABLE public.eggs ADD COLUMN IF NOT EXISTS start_date DATE;

-- 6. egg_number alanını ekle (eğer yoksa)
ALTER TABLE public.eggs ADD COLUMN IF NOT EXISTS egg_number INTEGER;

-- 7. is_deleted alanını ekle (eğer yoksa)
ALTER TABLE public.eggs ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;

-- 8. Güncellenmiş durumu kontrol et
SELECT '=== GÜNCELLENMİŞ EGGS TABLOSU YAPISI ===' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'eggs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 9. İndeksleri güncelle
DROP INDEX IF EXISTS idx_eggs_lay_date;
CREATE INDEX IF NOT EXISTS idx_eggs_hatch_date ON public.eggs(hatch_date);
CREATE INDEX IF NOT EXISTS idx_eggs_start_date ON public.eggs(start_date);
CREATE INDEX IF NOT EXISTS idx_eggs_incubation_id ON public.eggs(incubation_id);
CREATE INDEX IF NOT EXISTS idx_eggs_user_id ON public.eggs(user_id);
CREATE INDEX IF NOT EXISTS idx_eggs_egg_number ON public.eggs(egg_number);
CREATE INDEX IF NOT EXISTS idx_eggs_is_deleted ON public.eggs(is_deleted);

-- 10. RLS politikalarını kontrol et
SELECT '=== RLS POLİTİKALARI ===' as info;
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'eggs';

-- 11. Realtime durumunu kontrol et
SELECT '=== REALTIME DURUMU ===' as info;
SELECT 
    schemaname,
    tablename,
    pubname
FROM pg_publication_tables 
WHERE tablename = 'eggs';

-- 12. Eğer realtime yoksa ekle
ALTER PUBLICATION supabase_realtime ADD TABLE public.eggs;

-- 13. Mevcut verileri kontrol et
SELECT '=== MEVCUT VERİLER (İLK 5 KAYIT) ===' as info;
SELECT 
    id,
    incubation_id,
    egg_number,
    hatch_date,
    start_date,
    status,
    notes,
    user_id,
    created_at
FROM public.eggs 
LIMIT 5;

-- Başarı mesajı
SELECT 'Eggs tablosu lay_date sorunu başarıyla düzeltildi!' as status; 