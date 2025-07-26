-- Sıcaklık sensörü tablolarını tamamen kaldır
-- DİKKAT: Bu işlem geri alınamaz!

-- Önce bağımlılıkları kaldır
DROP TABLE IF EXISTS public.temperature_readings CASCADE;
DROP TABLE IF EXISTS public.temperature_sensors CASCADE;

-- İndeksleri de kaldır (otomatik olarak kaldırılır ama emin olmak için)
DROP INDEX IF EXISTS idx_temperature_sensors_user_id;
DROP INDEX IF EXISTS idx_temperature_readings_user_id;
DROP INDEX IF EXISTS idx_temperature_readings_sensor_id;
DROP INDEX IF EXISTS idx_temperature_readings_timestamp;

-- Migration dosyasını da kaldırmak için:
-- supabase/migrations/20250131170000-create-temperature-sensors.sql dosyasını silin 