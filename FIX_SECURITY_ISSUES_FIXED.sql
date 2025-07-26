-- Güvenlik Sorunları Düzeltme (Düzeltilmiş Versiyon)
-- Bu dosyayı Supabase Dashboard > SQL Editor'da çalıştırın

-- 1. Function Search Path Mutable Sorunu Düzeltme
-- Önce tüm trigger'ları sil, sonra fonksiyonu yeniden oluştur

-- Trigger'ları sil (CASCADE ile)
DROP TRIGGER IF EXISTS update_todos_updated_at ON public.todos CASCADE;
DROP TRIGGER IF EXISTS update_birds_updated_at ON public.birds CASCADE;
DROP TRIGGER IF EXISTS update_chicks_updated_at ON public.chicks CASCADE;
DROP TRIGGER IF EXISTS update_eggs_updated_at ON public.eggs CASCADE;
DROP TRIGGER IF EXISTS update_incubations_updated_at ON public.incubations CASCADE;
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles CASCADE;
DROP TRIGGER IF EXISTS update_user_notification_settings_updated_at ON public.user_notification_settings CASCADE;
DROP TRIGGER IF EXISTS update_user_notification_tokens_updated_at ON public.user_notification_tokens CASCADE;
DROP TRIGGER IF EXISTS update_notification_interactions_updated_at ON public.notification_interactions CASCADE;
DROP TRIGGER IF EXISTS update_temperature_sensors_updated_at ON public.temperature_sensors CASCADE;
DROP TRIGGER IF EXISTS update_temperature_readings_updated_at ON public.temperature_readings CASCADE;

-- Şimdi fonksiyonu sil ve yeniden oluştur
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;

-- Güvenli versiyonunu oluştur
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

-- Trigger'ları yeniden oluştur
-- Birds tablosu için
CREATE TRIGGER update_birds_updated_at
    BEFORE UPDATE ON public.birds
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Chicks tablosu için
CREATE TRIGGER update_chicks_updated_at
    BEFORE UPDATE ON public.chicks
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Eggs tablosu için
CREATE TRIGGER update_eggs_updated_at
    BEFORE UPDATE ON public.eggs
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Incubations tablosu için
CREATE TRIGGER update_incubations_updated_at
    BEFORE UPDATE ON public.incubations
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Profiles tablosu için
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- User notification settings tablosu için
CREATE TRIGGER update_user_notification_settings_updated_at
    BEFORE UPDATE ON public.user_notification_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- User notification tokens tablosu için
CREATE TRIGGER update_user_notification_tokens_updated_at
    BEFORE UPDATE ON public.user_notification_tokens
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Notification interactions tablosu için
CREATE TRIGGER update_notification_interactions_updated_at
    BEFORE UPDATE ON public.notification_interactions
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Temperature sensors tablosu için
CREATE TRIGGER update_temperature_sensors_updated_at
    BEFORE UPDATE ON public.temperature_sensors
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Temperature readings tablosu için
CREATE TRIGGER update_temperature_readings_updated_at
    BEFORE UPDATE ON public.temperature_readings
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Todos tablosu için
CREATE TRIGGER update_todos_updated_at
    BEFORE UPDATE ON public.todos
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- 2. Güvenlik için ek fonksiyonlar oluştur

-- Güvenli UUID oluşturma fonksiyonu
CREATE OR REPLACE FUNCTION public.gen_secure_uuid()
RETURNS UUID AS $$
BEGIN
    RETURN gen_random_uuid();
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

-- Güvenli timestamp oluşturma fonksiyonu
CREATE OR REPLACE FUNCTION public.gen_secure_timestamp()
RETURNS TIMESTAMPTZ AS $$
BEGIN
    RETURN NOW();
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

-- 3. Güvenlik için view'lar oluştur (opsiyonel)

-- Kullanıcıların sadece kendi verilerini görebileceği view'lar
CREATE OR REPLACE VIEW public.user_birds AS
SELECT * FROM public.birds 
WHERE user_id = auth.uid();

CREATE OR REPLACE VIEW public.user_chicks AS
SELECT * FROM public.chicks 
WHERE user_id = auth.uid();

CREATE OR REPLACE VIEW public.user_eggs AS
SELECT * FROM public.eggs 
WHERE user_id = auth.uid();

CREATE OR REPLACE VIEW public.user_incubations AS
SELECT * FROM public.incubations 
WHERE user_id = auth.uid();

-- 4. Fonksiyon güvenliğini kontrol et
SELECT 
    proname as function_name,
    prosecdef as security_definer,
    proconfig as search_path
FROM pg_proc 
WHERE proname = 'update_updated_at_column' 
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- Başarı mesajı
SELECT 'Güvenlik sorunları başarıyla düzeltildi!' as status; 