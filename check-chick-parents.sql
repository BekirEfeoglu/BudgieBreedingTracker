-- Chick tablosunda anne baba ID'lerini kontrol et
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
WHERE c.name LIKE '%Bilinmeyen%' OR c.name LIKE '%Unknown%'
ORDER BY c.created_at DESC
LIMIT 5; 