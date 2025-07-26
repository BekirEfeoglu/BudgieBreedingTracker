-- Incubation tablosundaki veriyi kontrol et
SELECT 
  i.id as incubation_id,
  i.name as incubation_name,
  i.male_bird_id,
  i.female_bird_id,
  b1.name as male_bird_name,
  b2.name as female_bird_name
FROM incubations i
LEFT JOIN birds b1 ON i.male_bird_id = b1.id
LEFT JOIN birds b2 ON i.female_bird_id = b2.id
WHERE i.id = '87bbeaf3-56f5-4059-aa74-066210196891'
LIMIT 1; 