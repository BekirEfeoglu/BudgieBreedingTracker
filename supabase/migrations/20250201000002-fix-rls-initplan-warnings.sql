-- RLS Initplan Uyarılarını Düzeltme Migration
-- Bu migration auth_rls_initplan uyarılarını çözer ve RLS performansını artırır

-- 1. USER_SUBSCRIPTIONS TABLOSU - RLS politikalarını optimize et
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can insert own subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can update own subscriptions" ON public.user_subscriptions;

CREATE POLICY "Users can view own subscriptions" ON public.user_subscriptions
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own subscriptions" ON public.user_subscriptions
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own subscriptions" ON public.user_subscriptions
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

-- 2. SUBSCRIPTION_USAGE TABLOSU - RLS politikalarını optimize et
DROP POLICY IF EXISTS "Users can view own usage" ON public.subscription_usage;
DROP POLICY IF EXISTS "Users can insert own usage" ON public.subscription_usage;
DROP POLICY IF EXISTS "Users can update own usage" ON public.subscription_usage;

CREATE POLICY "Users can view own usage" ON public.subscription_usage
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own usage" ON public.subscription_usage
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own usage" ON public.subscription_usage
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

-- 3. SUBSCRIPTION_EVENTS TABLOSU - RLS politikalarını optimize et
DROP POLICY IF EXISTS "Users can view own events" ON public.subscription_events;
DROP POLICY IF EXISTS "System can insert events" ON public.subscription_events;

CREATE POLICY "Users can view own events" ON public.subscription_events
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "System can insert events" ON public.subscription_events
  FOR INSERT WITH CHECK (true);

-- 4. PROFILES TABLOSU - Premium alanları için RLS politikalarını optimize et
DROP POLICY IF EXISTS "Users can update own subscription status" ON public.profiles;

CREATE POLICY "Users can update own subscription status" ON public.profiles
  FOR UPDATE USING ((SELECT auth.uid()) = id);

-- 5. TÜM DİĞER TABLOLAR İÇİN RLS POLİTİKALARINI OPTİMİZE ET

-- Birds tablosu
DROP POLICY IF EXISTS "Users can view own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can create own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete own birds" ON public.birds;

CREATE POLICY "Users can view own birds" ON public.birds
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own birds" ON public.birds
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own birds" ON public.birds
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own birds" ON public.birds
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Incubations tablosu
DROP POLICY IF EXISTS "Users can view own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can create own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can update own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can delete own incubations" ON public.incubations;

CREATE POLICY "Users can view own incubations" ON public.incubations
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own incubations" ON public.incubations
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own incubations" ON public.incubations
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own incubations" ON public.incubations
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Eggs tablosu
DROP POLICY IF EXISTS "Users can view own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can create own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can update own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can delete own eggs" ON public.eggs;

CREATE POLICY "Users can view own eggs" ON public.eggs
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own eggs" ON public.eggs
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own eggs" ON public.eggs
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own eggs" ON public.eggs
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Chicks tablosu
DROP POLICY IF EXISTS "Users can view own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can create own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can update own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can delete own chicks" ON public.chicks;

CREATE POLICY "Users can view own chicks" ON public.chicks
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own chicks" ON public.chicks
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own chicks" ON public.chicks
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own chicks" ON public.chicks
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Clutches tablosu
DROP POLICY IF EXISTS "Users can view own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can create own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can update own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can delete own clutches" ON public.clutches;

CREATE POLICY "Users can view own clutches" ON public.clutches
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own clutches" ON public.clutches
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own clutches" ON public.clutches
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own clutches" ON public.clutches
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Calendar tablosu
DROP POLICY IF EXISTS "Users can view own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can create own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can update own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can delete own calendar events" ON public.calendar;

CREATE POLICY "Users can view own calendar events" ON public.calendar
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own calendar events" ON public.calendar
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own calendar events" ON public.calendar
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own calendar events" ON public.calendar
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Photos tablosu
DROP POLICY IF EXISTS "Users can view own photos" ON public.photos;
DROP POLICY IF EXISTS "Users can create own photos" ON public.photos;
DROP POLICY IF EXISTS "Users can update own photos" ON public.photos;
DROP POLICY IF EXISTS "Users can delete own photos" ON public.photos;

CREATE POLICY "Users can view own photos" ON public.photos
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own photos" ON public.photos
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own photos" ON public.photos
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own photos" ON public.photos
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Backup settings tablosu
DROP POLICY IF EXISTS "Users can view own backup settings" ON public.backup_settings;
DROP POLICY IF EXISTS "Users can create own backup settings" ON public.backup_settings;
DROP POLICY IF EXISTS "Users can update own backup settings" ON public.backup_settings;

CREATE POLICY "Users can view own backup settings" ON public.backup_settings
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own backup settings" ON public.backup_settings
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own backup settings" ON public.backup_settings
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

-- Backup jobs tablosu
DROP POLICY IF EXISTS "Users can view own backup jobs" ON public.backup_jobs;
DROP POLICY IF EXISTS "Users can create own backup jobs" ON public.backup_jobs;
DROP POLICY IF EXISTS "Users can update own backup jobs" ON public.backup_jobs;

CREATE POLICY "Users can view own backup jobs" ON public.backup_jobs
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own backup jobs" ON public.backup_jobs
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own backup jobs" ON public.backup_jobs
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

-- Backup history tablosu
DROP POLICY IF EXISTS "Users can view own backup history" ON public.backup_history;

CREATE POLICY "Users can view own backup history" ON public.backup_history
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- Feedback tablosu
DROP POLICY IF EXISTS "Users can view own feedback" ON public.feedback;
DROP POLICY IF EXISTS "Users can create own feedback" ON public.feedback;

CREATE POLICY "Users can view own feedback" ON public.feedback
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own feedback" ON public.feedback
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

-- Notifications tablosu
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can create own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;

CREATE POLICY "Users can view own notifications" ON public.notifications
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own notifications" ON public.notifications
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own notifications" ON public.notifications
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own notifications" ON public.notifications
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- User notification settings tablosu
DROP POLICY IF EXISTS "Users can manage own notification settings" ON public.user_notification_settings;

CREATE POLICY "Users can manage own notification settings" ON public.user_notification_settings
  FOR ALL USING ((SELECT auth.uid()) = user_id);

-- Migration tamamlandı mesajı
SELECT 'RLS Initplan warnings fixed successfully' as message; 