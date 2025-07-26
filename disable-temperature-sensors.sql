-- Sıcaklık sensörü tablolarını geçici olarak devre dışı bırak
-- Bu dosya sıcaklık sensörü özelliği tamamen kaldırılana kadar kullanılabilir

-- RLS politikalarını kaldır
DROP POLICY IF EXISTS "Users can view their own temperature sensors" ON public.temperature_sensors;
DROP POLICY IF EXISTS "Users can insert their own temperature sensors" ON public.temperature_sensors;
DROP POLICY IF EXISTS "Users can update their own temperature sensors" ON public.temperature_sensors;
DROP POLICY IF EXISTS "Users can delete their own temperature sensors" ON public.temperature_sensors;

DROP POLICY IF EXISTS "Users can view their own temperature readings" ON public.temperature_readings;
DROP POLICY IF EXISTS "Users can insert their own temperature readings" ON public.temperature_readings;
DROP POLICY IF EXISTS "Users can update their own temperature readings" ON public.temperature_readings;
DROP POLICY IF EXISTS "Users can delete their own temperature readings" ON public.temperature_readings;

-- RLS'yi devre dışı bırak
ALTER TABLE public.temperature_sensors DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.temperature_readings DISABLE ROW LEVEL SECURITY;

-- Tabloları salt okunur yap (INSERT, UPDATE, DELETE engelle)
REVOKE INSERT, UPDATE, DELETE ON public.temperature_sensors FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.temperature_readings FROM authenticated;

-- Sadece SELECT izni ver
GRANT SELECT ON public.temperature_sensors TO authenticated;
GRANT SELECT ON public.temperature_readings TO authenticated;

-- Alternatif olarak: Tabloları tamamen gizle (daha güvenli)
-- ALTER TABLE public.temperature_sensors SET (autovacuum_enabled = false);
-- ALTER TABLE public.temperature_readings SET (autovacuum_enabled = false); 