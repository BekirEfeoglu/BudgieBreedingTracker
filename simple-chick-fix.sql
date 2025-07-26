-- Önce mevcut chick verilerini kontrol et
SELECT 
    id,
    name,
    egg_id,
    incubation_id,
    hatch_date
FROM chicks 
WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
ORDER BY created_at DESC;

-- Basit chick ismi düzeltme
UPDATE chicks 
SET name = 'Yavru ' || COALESCE(egg_id::text, '?')
WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
AND (name IS NULL OR name = '' OR name LIKE '%?%');

-- Sonucu kontrol et
SELECT 
    id,
    name,
    egg_id,
    incubation_id,
    hatch_date
FROM chicks 
WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
ORDER BY created_at DESC; 