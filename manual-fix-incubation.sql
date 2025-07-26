-- Manuel olarak incubation'ı düzelt
-- Bu script incubation'a anne-baba kuşları ekler

-- 1. Önce kuşların ID'lerini bul
SELECT 'Kuşların ID''leri:' as info;
SELECT 
    id,
    name,
    gender,
    color
FROM public.birds
WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
ORDER BY gender, name;

-- 2. Incubation'ı güncelle (kuş ID'lerini yukarıdaki sonuçlara göre değiştirin)
-- Dişi kuş ID'sini buraya yazın:
-- SET female_bird_id = 'DİŞİ_KUŞ_ID_BURAYA'
-- Erkek kuş ID'sini buraya yazın:
-- SET male_bird_id = 'ERKEK_KUŞ_ID_BURAYA'

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
AND user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3';

-- 3. Güncelleme sonrası kontrol
SELECT 'Güncelleme sonrası incubation:' as info;
SELECT 
    id,
    name,
    male_bird_id,
    female_bird_id,
    start_date
FROM public.incubations
WHERE id = '91cefecf-0bfc-4541-8494-8cbe17a6556d';

-- 4. Anne-baba kuşların detayları
SELECT 'Anne-baba kuşların detayları:' as info;
SELECT 
    i.id as incubation_id,
    i.name as incubation_name,
    mother.id as mother_id,
    mother.name as mother_name,
    mother.gender as mother_gender,
    father.id as father_id,
    father.name as father_name,
    father.gender as father_gender
FROM public.incubations i
LEFT JOIN public.birds mother ON i.female_bird_id = mother.id
LEFT JOIN public.birds father ON i.male_bird_id = father.id
WHERE i.id = '91cefecf-0bfc-4541-8494-8cbe17a6556d'; 