-- Master Security Fixes Migration
-- Bu migration tüm Supabase güvenlik uyarılarını düzeltir
-- 1. Function Search Path Mutable
-- 2. Auth RLS Initplan
-- 3. Multiple Permissive Policies

-- ========================================
-- 1. FUNCTION SEARCH PATH MUTABLE FIXES
-- ========================================

-- is_user_premium fonksiyonunu düzelt
CREATE OR REPLACE FUNCTION public.is_user_premium(user_uuid uuid)
RETURNS BOOLEAN AS $$
DECLARE
  subscription_status TEXT;
  subscription_expires TIMESTAMP WITH TIME ZONE;
BEGIN
  SELECT 
    p.subscription_status,
    p.subscription_expires_at
  INTO 
    subscription_status,
    subscription_expires
  FROM public.profiles p
  WHERE p.id = user_uuid;
  
  RETURN subscription_status = 'premium' AND 
         (subscription_expires IS NULL OR subscription_expires > now());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- check_feature_limit fonksiyonunu düzelt
CREATE OR REPLACE FUNCTION public.check_feature_limit(
  user_uuid uuid,
  feature_name text,
  current_count integer
)
RETURNS BOOLEAN AS $$
DECLARE
  user_status TEXT;
  user_limit INTEGER;
BEGIN
  -- Kullanıcının premium durumunu kontrol et
  SELECT subscription_status INTO user_status
  FROM public.profiles
  WHERE id = user_uuid;
  
  -- Premium kullanıcılar için sınırsız
  IF user_status = 'premium' THEN
    RETURN true;
  END IF;
  
  -- Ücretsiz kullanıcılar için limit kontrolü
  SELECT 
    CASE 
      WHEN feature_name = 'birds' THEN 3
      WHEN feature_name = 'incubations' THEN 1
      WHEN feature_name = 'eggs' THEN 6
      WHEN feature_name = 'chicks' THEN 3
      WHEN feature_name = 'notifications' THEN 5
      ELSE 0
    END INTO user_limit;
  
  RETURN current_count < user_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- update_subscription_status fonksiyonunu düzelt
CREATE OR REPLACE FUNCTION public.update_subscription_status(
  user_uuid uuid,
  new_status text,
  plan_id uuid DEFAULT NULL,
  expires_at timestamp with time zone DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  UPDATE public.profiles
  SET 
    subscription_status = new_status,
    subscription_plan_id = plan_id,
    subscription_expires_at = expires_at,
    updated_at = now()
  WHERE id = user_uuid;
  
  -- Abonelik olayını kaydet (eğer subscription_events tablosu varsa)
  BEGIN
    INSERT INTO public.subscription_events (user_id, event_type, event_data)
    VALUES (
      user_uuid,
      'status_changed',
      jsonb_build_object(
        'old_status', (SELECT subscription_status FROM public.profiles WHERE id = user_uuid),
        'new_status', new_status,
        'plan_id', plan_id,
        'expires_at', expires_at
      )
    );
  EXCEPTION
    WHEN undefined_table THEN
      -- Tablo yoksa sessizce devam et
      NULL;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- handle_updated_at fonksiyonunu düzelt
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- get_bird_family fonksiyonunu düzelt
CREATE OR REPLACE FUNCTION public.get_bird_family(bird_id uuid)
RETURNS TABLE(
  parent_id uuid,
  parent_name text,
  child_id uuid,
  child_name text,
  relationship_type text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b1.id as parent_id,
    b1.name as parent_name,
    b2.id as child_id,
    b2.name as child_name,
    'parent-child' as relationship_type
  FROM public.birds b1
  JOIN public.birds b2 ON b1.id = b2.parent_id
  WHERE b1.id = bird_id OR b2.id = bird_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- get_user_statistics fonksiyonunu düzelt
CREATE OR REPLACE FUNCTION public.get_user_statistics(user_uuid uuid)
RETURNS TABLE(
  total_birds integer,
  total_incubations integer,
  total_eggs integer,
  total_chicks integer,
  active_incubations integer
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(birds.count, 0) as total_birds,
    COALESCE(incubations.count, 0) as total_incubations,
    COALESCE(eggs.count, 0) as total_eggs,
    COALESCE(chicks.count, 0) as total_chicks,
    COALESCE(active_incubations.count, 0) as active_incubations
  FROM 
    (SELECT COUNT(*) as count FROM public.birds WHERE user_id = user_uuid) birds,
    (SELECT COUNT(*) as count FROM public.incubations WHERE user_id = user_uuid) incubations,
    (SELECT COUNT(*) as count FROM public.eggs WHERE user_id = user_uuid) eggs,
    (SELECT COUNT(*) as count FROM public.chicks WHERE user_id = user_uuid) chicks,
    (SELECT COUNT(*) as count FROM public.incubations WHERE user_id = user_uuid AND status = 'active') active_incubations;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ========================================
-- 2. RLS INITPLAN FIXES
-- ========================================

-- USER_SUBSCRIPTIONS TABLOSU - RLS politikalarını optimize et
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can insert own subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can update own subscriptions" ON public.user_subscriptions;

CREATE POLICY "Users can view own subscriptions" ON public.user_subscriptions
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own subscriptions" ON public.user_subscriptions
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own subscriptions" ON public.user_subscriptions
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

-- SUBSCRIPTION_USAGE TABLOSU - RLS politikalarını optimize et
DROP POLICY IF EXISTS "Users can view own usage" ON public.subscription_usage;
DROP POLICY IF EXISTS "Users can insert own usage" ON public.subscription_usage;
DROP POLICY IF EXISTS "Users can update own usage" ON public.subscription_usage;

CREATE POLICY "Users can view own usage" ON public.subscription_usage
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own usage" ON public.subscription_usage
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own usage" ON public.subscription_usage
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

-- SUBSCRIPTION_EVENTS TABLOSU - RLS politikalarını optimize et
DROP POLICY IF EXISTS "Users can view own events" ON public.subscription_events;
DROP POLICY IF EXISTS "System can insert events" ON public.subscription_events;

CREATE POLICY "Users can view own events" ON public.subscription_events
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "System can insert events" ON public.subscription_events
  FOR INSERT WITH CHECK (true);

-- PROFILES TABLOSU - Premium alanları için RLS politikalarını optimize et
DROP POLICY IF EXISTS "Users can update own subscription status" ON public.profiles;

CREATE POLICY "Users can update own subscription status" ON public.profiles
  FOR UPDATE USING ((SELECT auth.uid()) = id);

-- ========================================
-- 3. MULTIPLE PERMISSIVE POLICIES FIXES
-- ========================================

-- PROFILES TABLOSU - FOR ALL politikalarını kaldır ve spesifik politikalar oluştur
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Users can manage own profile" ON public.profiles;

-- Spesifik politikalar oluştur
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING ((SELECT auth.uid()) = id);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING ((SELECT auth.uid()) = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = id);

-- BIRDS TABLOSU - FOR ALL politikalarını kaldır
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.birds;
DROP POLICY IF EXISTS "Users can manage their own birds" ON public.birds;

-- Spesifik politikalar oluştur
CREATE POLICY "Users can view own birds" ON public.birds
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own birds" ON public.birds
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own birds" ON public.birds
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own birds" ON public.birds
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- CHICKS TABLOSU - FOR ALL politikalarını kaldır
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.chicks;
DROP POLICY IF EXISTS "Users can manage their own chicks" ON public.chicks;

-- Spesifik politikalar oluştur
CREATE POLICY "Users can view own chicks" ON public.chicks
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own chicks" ON public.chicks
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own chicks" ON public.chicks
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own chicks" ON public.chicks
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- EGGS TABLOSU - FOR ALL politikalarını kaldır
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.eggs;
DROP POLICY IF EXISTS "Users can manage their own eggs" ON public.eggs;

-- Spesifik politikalar oluştur
CREATE POLICY "Users can view own eggs" ON public.eggs
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own eggs" ON public.eggs
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own eggs" ON public.eggs
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own eggs" ON public.eggs
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- INCUBATIONS TABLOSU - FOR ALL politikalarını kaldır
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.incubations;
DROP POLICY IF EXISTS "Users can manage their own incubations" ON public.incubations;

-- Spesifik politikalar oluştur
CREATE POLICY "Users can view own incubations" ON public.incubations
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own incubations" ON public.incubations
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own incubations" ON public.incubations
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own incubations" ON public.incubations
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- USER_NOTIFICATION_SETTINGS TABLOSU - FOR ALL politikalarını kaldır
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

-- ========================================
-- 4. DİĞER TABLOLAR İÇİN RLS OPTİMİZASYONU
-- ========================================

-- CLUTCHES TABLOSU
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

-- CALENDAR TABLOSU
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

-- PHOTOS TABLOSU
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

-- BACKUP_SETTINGS TABLOSU
DROP POLICY IF EXISTS "Users can view own backup settings" ON public.backup_settings;
DROP POLICY IF EXISTS "Users can create own backup settings" ON public.backup_settings;
DROP POLICY IF EXISTS "Users can update own backup settings" ON public.backup_settings;

CREATE POLICY "Users can view own backup settings" ON public.backup_settings
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own backup settings" ON public.backup_settings
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own backup settings" ON public.backup_settings
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

-- BACKUP_JOBS TABLOSU
DROP POLICY IF EXISTS "Users can view own backup jobs" ON public.backup_jobs;
DROP POLICY IF EXISTS "Users can create own backup jobs" ON public.backup_jobs;
DROP POLICY IF EXISTS "Users can update own backup jobs" ON public.backup_jobs;

CREATE POLICY "Users can view own backup jobs" ON public.backup_jobs
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own backup jobs" ON public.backup_jobs
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own backup jobs" ON public.backup_jobs
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

-- BACKUP_HISTORY TABLOSU
DROP POLICY IF EXISTS "Users can view own backup history" ON public.backup_history;

CREATE POLICY "Users can view own backup history" ON public.backup_history
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- FEEDBACK TABLOSU
DROP POLICY IF EXISTS "Users can view own feedback" ON public.feedback;
DROP POLICY IF EXISTS "Users can create own feedback" ON public.feedback;

CREATE POLICY "Users can view own feedback" ON public.feedback
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own feedback" ON public.feedback
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

-- NOTIFICATIONS TABLOSU
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

-- ========================================
-- 5. SONUÇ KONTROLÜ
-- ========================================

-- Migration tamamlandı mesajı
SELECT 'Master security fixes applied successfully' as message;

-- Güvenlik durumunu kontrol et
SELECT 
  'SECURITY STATUS' as check_type,
  COUNT(*) as total_policies,
  COUNT(CASE WHEN cmd = 'SELECT' THEN 1 END) as select_policies,
  COUNT(CASE WHEN cmd = 'INSERT' THEN 1 END) as insert_policies,
  COUNT(CASE WHEN cmd = 'UPDATE' THEN 1 END) as update_policies,
  COUNT(CASE WHEN cmd = 'DELETE' THEN 1 END) as delete_policies
FROM pg_policies 
WHERE schemaname = 'public';

-- Function search path durumunu kontrol et
SELECT 
  'FUNCTION SEARCH PATH STATUS' as check_type,
  proname as function_name,
  CASE 
    WHEN prosrc LIKE '%SET search_path = public%' THEN '✅ FIXED'
    ELSE '❌ NEEDS FIX'
  END as status
FROM pg_proc 
WHERE proname IN ('is_user_premium', 'check_feature_limit', 'update_subscription_status', 'handle_updated_at', 'get_bird_family', 'get_user_statistics')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public'); 