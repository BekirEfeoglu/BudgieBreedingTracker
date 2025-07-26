-- Yavru kuşun anne-baba bilgilerini düzelt
-- Bu script yavru kuşu incubation'dan anne-baba bilgilerini alarak günceller

-- 1. Önce incubation'ın durumunu kontrol et
SELECT 'Incubation durumu:' as info;
SELECT 
    id,
    name,
    male_bird_id,
    female_bird_id,
    start_date
FROM public.incubations
WHERE id = '91cefecf-0bfc-4541-8494-8cbe17a6556d';

-- 2. Yavru kuşun mevcut durumu
SELECT 'Yavru kuşun mevcut durumu:' as info;
SELECT 
    id,
    name,
    mother_id,
    father_id,
    incubation_id
FROM public.chicks
WHERE incubation_id = '91cefecf-0bfc-4541-8494-8cbe17a6556d';

-- 3. Yavru kuşu incubation'dan anne-baba bilgilerini alarak güncelle
UPDATE public.chicks 
SET 
    mother_id = (
        SELECT female_bird_id 
        FROM public.incubations 
        WHERE id = '91cefecf-0bfc-4541-8494-8cbe17a6556d'
    ),
    father_id = (
        SELECT male_bird_id 
        FROM public.incubations 
        WHERE id = '91cefecf-0bfc-4541-8494-8cbe17a6556d'
    )
WHERE incubation_id = '91cefecf-0bfc-4541-8494-8cbe17a6556d'
AND (mother_id IS NULL OR father_id IS NULL);

-- 4. Güncelleme sonrası yavru kuşun durumu
SELECT 'Güncelleme sonrası yavru kuş:' as info;
SELECT 
    c.id,
    c.name,
    c.mother_id,
    c.father_id,
    c.incubation_id,
    mother.name as mother_name,
    father.name as father_name
FROM public.chicks c
LEFT JOIN public.birds mother ON c.mother_id = mother.id
LEFT JOIN public.birds father ON c.father_id = father.id
WHERE c.incubation_id = '91cefecf-0bfc-4541-8494-8cbe17a6556d';

-- 5. Eğer incubation'da da anne-baba yoksa, onları da güncelle
UPDATE public.incubations 
SET 
    female_bird_id = (
        SELECT id FROM public.birds 
        WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3' 
        AND gender = 'female' 
        ORDER BY name
        LIMIT 1
    ),
    male_bird_id = (
        SELECT id FROM public.birds 
        WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3' 
        AND gender = 'male' 
        ORDER BY name
        LIMIT 1
    )
WHERE id = '91cefecf-0bfc-4541-8494-8cbe17a6556d'
AND (female_bird_id IS NULL OR male_bird_id IS NULL);

-- 6. Final kontrol - tüm ilişkiler
SELECT 'Final kontrol - tüm ilişkiler:' as info;
SELECT 
    i.id as incubation_id,
    i.name as incubation_name,
    i.female_bird_id,
    i.male_bird_id,
    mother.name as mother_name,
    father.name as father_name,
    c.id as chick_id,
    c.name as chick_name,
    c.mother_id as chick_mother_id,
    c.father_id as chick_father_id
FROM public.incubations i
LEFT JOIN public.birds mother ON i.female_bird_id = mother.id
LEFT JOIN public.birds father ON i.male_bird_id = father.id
LEFT JOIN public.chicks c ON i.id = c.incubation_id
WHERE i.id = '91cefecf-0bfc-4541-8494-8cbe17a6556d'; 