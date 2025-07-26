-- 1. Önce mevcut chick verilerini kontrol et
SELECT 
    c.id,
    c.name,
    c.egg_id,
    c.incubation_id,
    e.egg_number,
    i.name as incubation_name
FROM chicks c
LEFT JOIN eggs e ON c.egg_id = e.id
LEFT JOIN incubations i ON c.incubation_id = i.id
WHERE c.user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
ORDER BY c.created_at DESC;

-- 2. Chick isimlerini düzelt (egg_number ile)
UPDATE chicks 
SET name = 'Yavru ' || COALESCE(
    (SELECT egg_number::text FROM eggs WHERE id = chicks.egg_id), 
    '?'
) || ' (' || COALESCE(
    (SELECT name FROM incubations WHERE id = chicks.incubation_id), 
    'Bilinmeyen Kuluçka'
) || ')'
WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
AND (name IS NULL OR name = '' OR name LIKE '%?%');

-- 3. Sonucu kontrol et
SELECT 
    c.id,
    c.name,
    c.egg_id,
    c.incubation_id,
    e.egg_number,
    i.name as incubation_name
FROM chicks c
LEFT JOIN eggs e ON c.egg_id = e.id
LEFT JOIN incubations i ON c.incubation_id = i.id
WHERE c.user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
ORDER BY c.created_at DESC; 