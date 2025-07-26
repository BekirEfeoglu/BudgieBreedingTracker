-- Chick isimlerini düzelt
UPDATE chicks 
SET name = CONCAT('Yavru ', COALESCE(egg_id::text, '?'), ' (', COALESCE(incubation_id::text, 'Bilinmeyen Kuluçka'), ')')
WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
AND (name IS NULL OR name = '' OR name LIKE '%?%');

-- Daha detaylı isim oluştur (incubation name ile)
UPDATE chicks 
SET name = CONCAT('Yavru ', 
                  CASE 
                    WHEN (SELECT egg_number FROM eggs WHERE id = chicks.egg_id) IS NOT NULL 
                    THEN (SELECT egg_number::text FROM eggs WHERE id = chicks.egg_id)
                    ELSE '?'
                  END, 
                  ' (', 
                  COALESCE((SELECT name FROM incubations WHERE id = chicks.incubation_id), 'Bilinmeyen Kuluçka'), 
                  ')')
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