-- Mevcut durumu kontrol et
-- Bu script mevcut verileri gösterir

-- 1. Incubation verisi
SELECT 'Incubation verisi:' as info;
SELECT 
    id,
    name,
    male_bird_id,
    female_bird_id,
    start_date,
    user_id
FROM public.incubations
WHERE id = '91cefecf-0bfc-4541-8494-8cbe17a6556d';

-- 2. Kuşlar
SELECT 'Kuşlar:' as info;
SELECT 
    id,
    name,
    gender,
    color
FROM public.birds
WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3';

-- 3. Yumurtalar
SELECT 'Yumurtalar:' as info;
SELECT 
    id,
    incubation_id,
    egg_number,
    status
FROM public.eggs
WHERE incubation_id = '91cefecf-0bfc-4541-8494-8cbe17a6556d';

-- 4. Yavrular
SELECT 'Yavrular:' as info;
SELECT 
    id,
    name,
    mother_id,
    father_id,
    incubation_id
FROM public.chicks
WHERE incubation_id = '91cefecf-0bfc-4541-8494-8cbe17a6556d'; 