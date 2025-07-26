-- Incubation'a anne-baba kuşları ekle
-- Bu script incubation kayıtlarına anne-baba kuşları ekler

-- 1. Mevcut incubation verilerini kontrol et
SELECT 'Mevcut incubation verileri:' as info;
SELECT 
    id,
    name,
    male_bird_id,
    female_bird_id,
    start_date,
    user_id
FROM public.incubations
ORDER BY created_at DESC;

-- 2. Mevcut kuşları kontrol et
SELECT 'Mevcut kuşlar:' as info;
SELECT 
    id,
    name,
    gender,
    color,
    user_id
FROM public.birds
ORDER BY created_at DESC;

-- 3. Incubation'a anne-baba kuşları ekle (örnek)
-- Bu kısmı kendi kuşlarınızın ID'leri ile güncelleyin
UPDATE public.incubations 
SET 
    female_bird_id = (
        SELECT id FROM public.birds 
        WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3' 
        AND gender = 'female' 
        LIMIT 1
    ),
    male_bird_id = (
        SELECT id FROM public.birds 
        WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3' 
        AND gender = 'male' 
        LIMIT 1
    )
WHERE id = '91cefecf-0bfc-4541-8494-8cbe17a6556d'
AND user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3';

-- 4. Güncelleme sonrası kontrol
SELECT 'Güncelleme sonrası incubation verileri:' as info;
SELECT 
    id,
    name,
    male_bird_id,
    female_bird_id,
    start_date,
    user_id
FROM public.incubations
WHERE id = '91cefecf-0bfc-4541-8494-8cbe17a6556d'
ORDER BY created_at DESC;

-- 5. Anne-baba kuşların detayları
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