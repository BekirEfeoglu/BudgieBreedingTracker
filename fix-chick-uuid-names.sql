-- Chick isimlerini UUID'den temizle ve doğru isimle değiştir
UPDATE chicks 
SET name = 'Yavru ' || COALESCE(
    (SELECT egg_number::text FROM eggs WHERE id = chicks.egg_id), 
    '?'
) || ' (' || COALESCE(
    (SELECT name FROM incubations WHERE id = chicks.incubation_id), 
    'Bilinmeyen Kuluçka'
) || ')'
WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
AND (
    name IS NULL 
    OR name = '' 
    OR name LIKE '%?%'
    OR name LIKE '%ed05cd6e%'  -- UUID içeren isimler
    OR name LIKE '%87bbeaf3%'  -- UUID içeren isimler
    OR LENGTH(name) > 50       -- Çok uzun isimler (UUID'ler)
);

-- Sonucu kontrol et
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