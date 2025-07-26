-- Incubation adını kontrol et
-- Bu script incubation'ın neden 1 olarak göründüğünü araştırır

-- 1. Incubation kaydını kontrol et
SELECT 'Incubation kaydı:' as info;
SELECT 
    id,
    name,
    male_bird_id,
    female_bird_id,
    start_date,
    user_id
FROM public.incubations
WHERE id = '91cefecf-0bfc-4541-8494-8cbe17a6556d';

-- 2. Tüm incubation'ları listele
SELECT 'Tüm incubationlar:' as info;
SELECT 
    id,
    name,
    male_bird_id,
    female_bird_id,
    start_date
FROM public.incubations
WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
ORDER BY start_date DESC;

-- 3. Incubation adını güncelle (eğer gerçekten 1 ise)
UPDATE public.incubations 
SET name = CONCAT(
    'Kuluçka ',
    COALESCE(mother.name, 'Bilinmeyen'),
    ' & ',
    COALESCE(father.name, 'Bilinmeyen')
)
FROM public.birds mother, public.birds father
WHERE public.incubations.id = '91cefecf-0bfc-4541-8494-8cbe17a6556d'
AND mother.id = public.incubations.female_bird_id
AND father.id = public.incubations.male_bird_id
AND public.incubations.name = '1';

-- 4. Güncelleme sonrası kontrol
SELECT 'Güncelleme sonrası incubation:' as info;
SELECT 
    id,
    name,
    male_bird_id,
    female_bird_id
FROM public.incubations
WHERE id = '91cefecf-0bfc-4541-8494-8cbe17a6556d'; 