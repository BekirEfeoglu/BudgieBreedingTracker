-- RLS Policy Performans Optimizasyonu
-- Bu dosyayı Supabase Dashboard > SQL Editor'da çalıştırın

-- 1. Birds tablosu için tüm çakışan politikaları temizle
DROP POLICY IF EXISTS "Users can view own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can insert own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can view their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can insert their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can manage their own birds" ON public.birds;

-- Optimize edilmiş tek policy oluştur
CREATE POLICY "Users can manage their own birds" 
ON public.birds 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 2. Chicks tablosu için tüm çakışan politikaları temizle
DROP POLICY IF EXISTS "Users can view own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can insert own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can update own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can delete own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can create own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can view their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can insert their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can update their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can delete their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can manage their own chicks" ON public.chicks;

CREATE POLICY "Users can manage their own chicks" 
ON public.chicks 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 3. Eggs tablosu için tüm çakışan politikaları temizle
DROP POLICY IF EXISTS "Users can view own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can insert own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can update own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can delete own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can create own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can view their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can insert their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can update their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can delete their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can manage their own eggs" ON public.eggs;

CREATE POLICY "Users can manage their own eggs" 
ON public.eggs 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 4. Incubations tablosu için tüm çakışan politikaları temizle
DROP POLICY IF EXISTS "Users can view own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can insert own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can update own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can delete own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can create own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can view their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can insert their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can update their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can delete their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can manage their own incubations" ON public.incubations;

CREATE POLICY "Users can manage their own incubations" 
ON public.incubations 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 5. Profiles tablosu için politikaları düzelt
DROP POLICY IF EXISTS "Users can view their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can delete their own profiles" ON public.profiles;

CREATE POLICY "Users can manage their own profiles" 
ON public.profiles 
FOR ALL 
USING ((SELECT auth.uid()) = id);

-- 6. User notification settings tablosu için politikaları düzelt
DROP POLICY IF EXISTS "Users can view their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can insert their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can update their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can delete their own notification settings" ON public.user_notification_settings;

CREATE POLICY "Users can manage their own notification settings" 
ON public.user_notification_settings 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 7. User notification tokens tablosu için politikaları düzelt
DROP POLICY IF EXISTS "Users can manage their own notification tokens" ON public.user_notification_tokens;

CREATE POLICY "Users can manage their own notification tokens" 
ON public.user_notification_tokens 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 8. Notification interactions tablosu için politikaları düzelt
DROP POLICY IF EXISTS "Users can manage their own notification interactions" ON public.notification_interactions;

CREATE POLICY "Users can manage their own notification interactions" 
ON public.notification_interactions 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 9. Temperature sensors tablosu için politikaları düzelt
DROP POLICY IF EXISTS "Users can view their own temperature sensors" ON public.temperature_sensors;
DROP POLICY IF EXISTS "Users can insert their own temperature sensors" ON public.temperature_sensors;
DROP POLICY IF EXISTS "Users can update their own temperature sensors" ON public.temperature_sensors;
DROP POLICY IF EXISTS "Users can delete their own temperature sensors" ON public.temperature_sensors;

CREATE POLICY "Users can manage their own temperature sensors" 
ON public.temperature_sensors 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 10. Temperature readings tablosu için politikaları düzelt
DROP POLICY IF EXISTS "Users can view their own temperature readings" ON public.temperature_readings;
DROP POLICY IF EXISTS "Users can insert their own temperature readings" ON public.temperature_readings;
DROP POLICY IF EXISTS "Users can update their own temperature readings" ON public.temperature_readings;
DROP POLICY IF EXISTS "Users can delete their own temperature readings" ON public.temperature_readings;

CREATE POLICY "Users can manage their own temperature readings" 
ON public.temperature_readings 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 11. Todos tablosu için politikaları düzelt (eğer varsa)
DROP POLICY IF EXISTS "Users can view their own todos" ON public.todos;
DROP POLICY IF EXISTS "Users can insert their own todos" ON public.todos;
DROP POLICY IF EXISTS "Users can update their own todos" ON public.todos;
DROP POLICY IF EXISTS "Users can delete their own todos" ON public.todos;

CREATE POLICY "Users can manage their own todos" 
ON public.todos 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- RLS'yi tüm tablolarda etkinleştir
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.temperature_sensors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.temperature_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;

-- Başarı mesajı
SELECT 'RLS Policy performans optimizasyonu tamamlandı!' as status; 