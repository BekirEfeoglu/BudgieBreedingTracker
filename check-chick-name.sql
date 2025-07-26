-- Chick verilerini kontrol et
SELECT 
    id,
    name,
    egg_id,
    incubation_id,
    hatch_date,
    mother_id,
    father_id,
    health_notes,
    created_at,
    updated_at
FROM chicks 
WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
ORDER BY created_at DESC;

-- Chick oluşturma işlemini test et
-- Önce egg verilerini kontrol et
SELECT 
    e.id as egg_id,
    e.egg_number,
    e.incubation_id,
    i.name as incubation_name,
    i.female_bird_id,
    i.male_bird_id
FROM eggs e
LEFT JOIN incubations i ON e.incubation_id = i.id
WHERE e.user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
AND e.status = 'hatched'
ORDER BY e.created_at DESC; 