-- Chick tablosundaki alan isimlerini kontrol et
-- Bu script chick tablosunun yapısını gösterir

-- 1. Chick tablosu yapısı
SELECT 'Chick tablosu yapısı:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'chicks' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Chick verisi (tüm alanlar)
SELECT 'Chick verisi (tüm alanlar):' as info;
SELECT 
    id,
    name,
    user_id,
    egg_id,
    incubation_id,
    mother_id,
    father_id,
    hatch_date,
    created_at,
    updated_at
FROM public.chicks
ORDER BY created_at DESC;

-- 3. Chick verisi (sadece önemli alanlar)
SELECT 'Chick verisi (sadece önemli alanlar):' as info;
SELECT 
    id,
    name,
    egg_id,
    incubation_id,
    mother_id,
    father_id
FROM public.chicks
WHERE name LIKE '%BELLA%'
ORDER BY created_at DESC; 