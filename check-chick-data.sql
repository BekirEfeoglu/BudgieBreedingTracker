-- Yavru kuş verilerini kontrol et
-- Bu script yavru kuşların incubation ve egg bilgilerini gösterir

-- 1. Tüm yavru kuşlar
SELECT 'Tüm yavru kuşlar:' as info;
SELECT 
    c.id,
    c.name,
    c.incubation_id,
    c.egg_id,
    c.mother_id,
    c.father_id,
    c.hatch_date
FROM public.chicks c
ORDER BY c.hatch_date DESC;

-- 2. Yavru kuş detayları (join ile)
SELECT 'Yavru kuş detayları:' as info;
SELECT 
    c.id as chick_id,
    c.name as chick_name,
    c.incubation_id,
    c.egg_id,
    i.name as incubation_name,
    e.egg_number,
    mother.name as mother_name,
    father.name as father_name,
    c.hatch_date
FROM public.chicks c
LEFT JOIN public.incubations i ON c.incubation_id = i.id
LEFT JOIN public.eggs e ON c.egg_id = e.id
LEFT JOIN public.birds mother ON c.mother_id = mother.id
LEFT JOIN public.birds father ON c.father_id = father.id
ORDER BY c.hatch_date DESC;

-- 3. Belirli yavru kuş için detay
SELECT 'Belirli yavru kuş detayı:' as info;
SELECT 
    c.id as chick_id,
    c.name as chick_name,
    c.incubation_id,
    c.egg_id,
    i.name as incubation_name,
    e.egg_number,
    mother.name as mother_name,
    father.name as father_name,
    c.hatch_date
FROM public.chicks c
LEFT JOIN public.incubations i ON c.incubation_id = i.id
LEFT JOIN public.eggs e ON c.egg_id = e.id
LEFT JOIN public.birds mother ON c.mother_id = mother.id
LEFT JOIN public.birds father ON c.father_id = father.id
WHERE c.name LIKE '%BELLA%'
ORDER BY c.hatch_date DESC; 