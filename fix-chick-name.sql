-- Yavru kuşun adını düzelt
-- Bu script yavru kuşun adını anne-baba isimleriyle günceller

-- 1. Mevcut yavru kuş durumu
SELECT 'Mevcut yavru kuş:' as info;
SELECT 
    c.id,
    c.name,
    c.mother_id,
    c.father_id,
    mother.name as mother_name,
    father.name as father_name
FROM public.chicks c
LEFT JOIN public.birds mother ON c.mother_id = mother.id
LEFT JOIN public.birds father ON c.father_id = father.id
WHERE c.id = '5d9c3fc0-efd6-4cab-835c-90cb22d27172';

-- 2. Yavru kuşun adını güncelle
UPDATE public.chicks 
SET name = (
    SELECT CONCAT(
        'Yavru ',
        COALESCE(mother.name, 'Bilinmeyen'),
        ' & ',
        COALESCE(father.name, 'Bilinmeyen')
    )
    FROM public.birds mother
    LEFT JOIN public.birds father ON father.id = public.chicks.father_id
    WHERE mother.id = public.chicks.mother_id
)
WHERE id = '5d9c3fc0-efd6-4cab-835c-90cb22d27172'
AND name LIKE '%Bilinmeyen%';

-- 3. Güncelleme sonrası kontrol
SELECT 'Güncelleme sonrası yavru kuş:' as info;
SELECT 
    c.id,
    c.name,
    c.mother_id,
    c.father_id,
    mother.name as mother_name,
    father.name as father_name
FROM public.chicks c
LEFT JOIN public.birds mother ON c.mother_id = mother.id
LEFT JOIN public.birds father ON c.father_id = father.id
WHERE c.id = '5d9c3fc0-efd6-4cab-835c-90cb22d27172';

-- 4. Tüm yavru kuşları kontrol et
SELECT 'Tüm yavru kuşlar:' as info;
SELECT 
    c.id,
    c.name,
    c.incubation_id,
    mother.name as mother_name,
    father.name as father_name
FROM public.chicks c
LEFT JOIN public.birds mother ON c.mother_id = mother.id
LEFT JOIN public.birds father ON c.father_id = father.id
WHERE c.incubation_id = '91cefecf-0bfc-4541-8494-8cbe17a6556d'; 