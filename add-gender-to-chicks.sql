-- Mevcut chick verilerine gender alanı ekle
UPDATE chicks 
SET gender = 'unknown'
WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
AND (gender IS NULL OR gender = '');

-- Sonucu kontrol et
SELECT 
    id,
    name,
    gender,
    egg_id,
    incubation_id
FROM chicks 
WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
ORDER BY created_at DESC; 