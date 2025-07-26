-- Soyağacı için chick anne baba bilgilerini kontrol et
SELECT 
    c.id as chick_id,
    c.name as chick_name,
    c.mother_id,
    c.father_id,
    b1.name as mother_name,
    b2.name as father_name,
    c.incubation_id,
    i.name as incubation_name,
    i.female_bird_id,
    i.male_bird_id,
    b3.name as incubation_mother_name,
    b4.name as incubation_father_name
FROM chicks c
LEFT JOIN birds b1 ON c.mother_id = b1.id
LEFT JOIN birds b2 ON c.father_id = b2.id
LEFT JOIN incubations i ON c.incubation_id = i.id
LEFT JOIN birds b3 ON i.female_bird_id = b3.id
LEFT JOIN birds b4 ON i.male_bird_id = b4.id
WHERE c.user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
ORDER BY c.created_at DESC;

-- Chick anne baba bilgilerini incubation'dan güncelle
UPDATE chicks 
SET 
    mother_id = i.female_bird_id,
    father_id = i.male_bird_id
FROM incubations i
WHERE chicks.incubation_id = i.id
AND chicks.user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
AND (chicks.mother_id IS NULL OR chicks.father_id IS NULL);

-- Güncelleme sonrası kontrol
SELECT 
    c.id as chick_id,
    c.name as chick_name,
    c.mother_id,
    c.father_id,
    b1.name as mother_name,
    b2.name as father_name
FROM chicks c
LEFT JOIN birds b1 ON c.mother_id = b1.id
LEFT JOIN birds b2 ON c.father_id = b2.id
WHERE c.user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
ORDER BY c.created_at DESC; 