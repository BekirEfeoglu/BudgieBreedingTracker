-- Chick'in incubation verisini kontrol et
SELECT 
  c.id as chick_id,
  c.name as chick_name,
  c.incubation_id,
  c.egg_id,
  i.id as incubation_table_id,
  i.name as incubation_name,
  i.parent_bird_1_id,
  i.parent_bird_2_id,
  b1.name as parent_1_name,
  b2.name as parent_2_name
FROM chicks c
LEFT JOIN incubations i ON c.incubation_id = i.id
LEFT JOIN birds b1 ON i.parent_bird_1_id = b1.id
LEFT JOIN birds b2 ON i.parent_bird_2_id = b2.id
WHERE c.name LIKE '%Bilinmeyen%' OR c.name LIKE '%Unknown%'
ORDER BY c.created_at DESC
LIMIT 5; 