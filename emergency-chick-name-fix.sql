-- ACİL DURUM: Tüm chick isimlerini düzelt
-- Önce mevcut durumu kontrol et
SELECT 
    id,
    name,
    LENGTH(name) as name_length,
    egg_id,
    incubation_id
FROM chicks 
WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
ORDER BY created_at DESC;

-- Tüm problematik chick isimlerini düzelt
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
    OR name LIKE '%ed05cd6e%'
    OR name LIKE '%87bbeaf3%'
    OR name LIKE '%5a1d%'
    OR name LIKE '%4198%'
    OR name LIKE '%9f18%'
    OR name LIKE '%976f%'
    OR name LIKE '%0ee7%'
    OR name LIKE '%2ba6%'
    OR name LIKE '%56f5%'
    OR name LIKE '%4059%'
    OR name LIKE '%aa74%'
    OR name LIKE '%0662%'
    OR name LIKE '%1019%'
    OR name LIKE '%6891%'
    OR LENGTH(name) > 30
);

-- Sonucu kontrol et
SELECT 
    id,
    name,
    LENGTH(name) as name_length,
    egg_id,
    incubation_id
FROM chicks 
WHERE user_id = 'd055c311-fba9-4d78-adbf-ee01658e72e3'
ORDER BY created_at DESC; 