-- Eggs tablosu schema kontrolü
-- Mevcut alanları ve kısıtlamaları göster

-- 1. Mevcut eggs tablosu yapısını kontrol et
SELECT '=== EGGS TABLOSU SCHEMA ===' as info;

SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'eggs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. NOT NULL kısıtlamalarını kontrol et
SELECT '=== NOT NULL KISITLAMALARI ===' as info;

SELECT 
    tc.table_name,
    tc.column_name,
    tc.is_nullable,
    tc.data_type
FROM information_schema.columns tc
WHERE tc.table_name = 'eggs' 
AND tc.table_schema = 'public'
AND tc.is_nullable = 'NO'
ORDER BY tc.ordinal_position;

-- 3. Mevcut verileri kontrol et
SELECT '=== MEVCUT VERİLER (İLK 5 KAYIT) ===' as info;

SELECT 
    id,
    incubation_id,
    egg_number,
    lay_date,
    hatch_date,
    status,
    notes,
    user_id,
    created_at,
    updated_at
FROM public.eggs 
LIMIT 5;

-- 4. Alan sayılarını kontrol et
SELECT '=== ALAN SAYILARI ===' as info;

SELECT 
    COUNT(*) as total_columns,
    COUNT(CASE WHEN column_name = 'lay_date' THEN 1 END) as has_lay_date,
    COUNT(CASE WHEN column_name = 'hatch_date' THEN 1 END) as has_hatch_date,
    COUNT(CASE WHEN column_name = 'start_date' THEN 1 END) as has_start_date
FROM information_schema.columns 
WHERE table_name = 'eggs' 
AND table_schema = 'public'; 