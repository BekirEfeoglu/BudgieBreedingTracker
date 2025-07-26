-- Multiple Permissive Policies Uyarısını Düzeltme Migration
-- Bu migration multiple_permissive_policies uyarısını çözer

-- 1. PROFILES TABLOSU - FOR ALL politikalarını kaldır ve spesifik politikalar oluştur
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Users can manage own profile" ON public.profiles;

-- Spesifik politikalar oluştur
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING ((SELECT auth.uid()) = id);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING ((SELECT auth.uid()) = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = id);

-- 2. BIRDS TABLOSU - FOR ALL politikalarını kaldır ve spesifik politikalar oluştur
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.birds;
DROP POLICY IF EXISTS "Users can manage their own birds" ON public.birds;

-- Spesifik politikalar oluştur (zaten mevcut olanları koru)
-- Bu politikalar zaten 20250201000002-fix-rls-initplan-warnings.sql'de oluşturuldu

-- 3. CHICKS TABLOSU - FOR ALL politikalarını kaldır ve spesifik politikalar oluştur
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.chicks;
DROP POLICY IF EXISTS "Users can manage their own chicks" ON public.chicks;

-- Spesifik politikalar oluştur (zaten mevcut olanları koru)
-- Bu politikalar zaten 20250201000002-fix-rls-initplan-warnings.sql'de oluşturuldu

-- 4. EGGS TABLOSU - FOR ALL politikalarını kaldır ve spesifik politikalar oluştur
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.eggs;
DROP POLICY IF EXISTS "Users can manage their own eggs" ON public.eggs;

-- Spesifik politikalar oluştur (zaten mevcut olanları koru)
-- Bu politikalar zaten 20250201000002-fix-rls-initplan-warnings.sql'de oluşturuldu

-- 5. INCUBATIONS TABLOSU - FOR ALL politikalarını kaldır ve spesifik politikalar oluştur
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.incubations;
DROP POLICY IF EXISTS "Users can manage their own incubations" ON public.incubations;

-- Spesifik politikalar oluştur (zaten mevcut olanları koru)
-- Bu politikalar zaten 20250201000002-fix-rls-initplan-warnings.sql'de oluşturuldu

-- 6. USER_NOTIFICATION_SETTINGS TABLOSU - FOR ALL politikalarını kaldır ve spesifik politikalar oluştur
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can manage their own notification settings" ON public.user_notification_settings;

-- Spesifik politikalar oluştur
CREATE POLICY "Users can view own notification settings" ON public.user_notification_settings
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own notification settings" ON public.user_notification_settings
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own notification settings" ON public.user_notification_settings
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own notification settings" ON public.user_notification_settings
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- 7. USER_NOTIFICATION_TOKENS TABLOSU - FOR ALL politikalarını kaldır ve spesifik politikalar oluştur
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.user_notification_tokens;
DROP POLICY IF EXISTS "Users can manage their own notification tokens" ON public.user_notification_tokens;

-- Spesifik politikalar oluştur
CREATE POLICY "Users can view own notification tokens" ON public.user_notification_tokens
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own notification tokens" ON public.user_notification_tokens
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own notification tokens" ON public.user_notification_tokens
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own notification tokens" ON public.user_notification_tokens
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- 8. NOTIFICATION_INTERACTIONS TABLOSU - FOR ALL politikalarını kaldır ve spesifik politikalar oluştur
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.notification_interactions;
DROP POLICY IF EXISTS "Users can manage their own notification interactions" ON public.notification_interactions;

-- Spesifik politikalar oluştur
CREATE POLICY "Users can view own notification interactions" ON public.notification_interactions
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own notification interactions" ON public.notification_interactions
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own notification interactions" ON public.notification_interactions
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own notification interactions" ON public.notification_interactions
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- 9. TEMPERATURE_SENSORS TABLOSU - FOR ALL politikalarını kaldır ve spesifik politikalar oluştur
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.temperature_sensors;
DROP POLICY IF EXISTS "Users can manage their own temperature sensors" ON public.temperature_sensors;

-- Spesifik politikalar oluştur
CREATE POLICY "Users can view own temperature sensors" ON public.temperature_sensors
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own temperature sensors" ON public.temperature_sensors
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own temperature sensors" ON public.temperature_sensors
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own temperature sensors" ON public.temperature_sensors
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- 10. TEMPERATURE_READINGS TABLOSU - FOR ALL politikalarını kaldır ve spesifik politikalar oluştur
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.temperature_readings;
DROP POLICY IF EXISTS "Users can manage their own temperature readings" ON public.temperature_readings;

-- Spesifik politikalar oluştur
CREATE POLICY "Users can view own temperature readings" ON public.temperature_readings
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own temperature readings" ON public.temperature_readings
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own temperature readings" ON public.temperature_readings
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own temperature readings" ON public.temperature_readings
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- 11. TODOS TABLOSU - FOR ALL politikalarını kaldır ve spesifik politikalar oluştur
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.todos;
DROP POLICY IF EXISTS "Users can manage their own todos" ON public.todos;

-- Spesifik politikalar oluştur
CREATE POLICY "Users can view own todos" ON public.todos
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own todos" ON public.todos
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own todos" ON public.todos
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own todos" ON public.todos
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- 12. MEVCUT POLİTİKALARI KONTROL ET
SELECT 
  'MULTIPLE PERMISSIVE POLICIES FIXED' as status,
  schemaname,
  tablename,
  policyname,
  cmd,
  permissive
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('profiles', 'birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings', 'user_notification_tokens', 'notification_interactions', 'temperature_sensors', 'temperature_readings', 'todos')
ORDER BY tablename, cmd;

-- Migration tamamlandı mesajı
SELECT 'Multiple permissive policies warnings fixed successfully' as message; 