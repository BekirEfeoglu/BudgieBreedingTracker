-- Incubations tablosunun sütun adlarını kontrol et
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'incubations'
ORDER BY ordinal_position; 