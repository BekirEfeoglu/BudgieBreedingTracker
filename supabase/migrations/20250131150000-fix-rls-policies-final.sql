-- RLS politikalarını düzelt - auth.uid() performans sorunlarını çöz
-- Bu migration tüm çakışan politikaları temizler ve optimize edilmiş versiyonlarını oluşturur

-- 1. Birds tablosu için politikaları düzelt
DROP POLICY IF EXISTS "Users can view their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can create their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can manage their own birds" ON public.birds;

-- Optimize edilmiş tek policy oluştur
CREATE POLICY "Users can manage their own birds" 
ON public.birds 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 2. Chicks tablosu için politikaları düzelt
DROP POLICY IF EXISTS "Users can view their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can create their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can update their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can delete their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can manage their own chicks" ON public.chicks;

CREATE POLICY "Users can manage their own chicks" 
ON public.chicks 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 3. Eggs tablosu için politikaları düzelt
DROP POLICY IF EXISTS "Users can view their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can create their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can update their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can delete their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can manage their own eggs" ON public.eggs;

CREATE POLICY "Users can manage their own eggs" 
ON public.eggs 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 4. Incubations tablosu için politikaları düzelt
DROP POLICY IF EXISTS "Users can view their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can create their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can update their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can delete their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can manage their own incubations" ON public.incubations;

CREATE POLICY "Users can manage their own incubations" 
ON public.incubations 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 5. Clutches tablosu için politikaları düzelt (eğer varsa)
DROP POLICY IF EXISTS "Users can view their own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can create their own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can update their own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can delete their own clutches" ON public.clutches;

CREATE POLICY "Users can manage their own clutches" 
ON public.clutches 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 6. Calendar tablosu için politikaları düzelt
DROP POLICY IF EXISTS "Users can view their own calendar" ON public.calendar;
DROP POLICY IF EXISTS "Users can view their own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can create their own calendar" ON public.calendar;
DROP POLICY IF EXISTS "Users can create their own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can update their own calendar" ON public.calendar;
DROP POLICY IF EXISTS "Users can update their own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can delete their own calendar" ON public.calendar;
DROP POLICY IF EXISTS "Users can delete their own calendar events" ON public.calendar;

CREATE POLICY "Users can manage their own calendar events" 
ON public.calendar 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 7. Backup tabloları için politikaları düzelt
DROP POLICY IF EXISTS "Users can view their own backup jobs" ON public.backup_jobs;
DROP POLICY IF EXISTS "Users can create their own backup jobs" ON public.backup_jobs;
DROP POLICY IF EXISTS "Users can update their own backup jobs" ON public.backup_jobs;

CREATE POLICY "Users can manage their own backup jobs" 
ON public.backup_jobs 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view their own backup settings" ON public.backup_settings;
DROP POLICY IF EXISTS "Users can create their own backup settings" ON public.backup_settings;
DROP POLICY IF EXISTS "Users can update their own backup settings" ON public.backup_settings;

CREATE POLICY "Users can manage their own backup settings" 
ON public.backup_settings 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view their own backup history" ON public.backup_history;

CREATE POLICY "Users can view their own backup history" 
ON public.backup_history 
FOR SELECT 
USING ((SELECT auth.uid()) = user_id);

-- 8. Notification tabloları için politikaları düzelt
DROP POLICY IF EXISTS "Users can manage their own notification tokens" ON public.user_notification_tokens;
DROP POLICY IF EXISTS "Users can manage their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can manage their own notification interactions" ON public.notification_interactions;

CREATE POLICY "Users can manage their own notification tokens" 
ON public.user_notification_tokens 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can manage their own notification settings" 
ON public.user_notification_settings 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can manage their own notification interactions" 
ON public.notification_interactions 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 9. Profiles tablosu için politikaları düzelt
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;

CREATE POLICY "Users can manage their own profile" 
ON public.profiles 
FOR ALL 
USING ((SELECT auth.uid()) = id);

-- 10. Photos tablosu için politikaları düzelt
DROP POLICY IF EXISTS "Users can view their own photos" ON public.photos;
DROP POLICY IF EXISTS "Users can insert their own photos" ON public.photos;
DROP POLICY IF EXISTS "Users can update their own photos" ON public.photos;
DROP POLICY IF EXISTS "Users can delete their own photos" ON public.photos;

CREATE POLICY "Users can manage their own photos" 
ON public.photos 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 11. Feedback tablosu için politikaları düzelt
DROP POLICY IF EXISTS "Users can view their own feedback" ON public.feedback;
DROP POLICY IF EXISTS "Users can insert feedback" ON public.feedback;
DROP POLICY IF EXISTS "Users can update their own feedback" ON public.feedback;

CREATE POLICY "Users can view their own feedback" 
ON public.feedback 
FOR SELECT 
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert feedback" 
ON public.feedback 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Users can update their own feedback" 
ON public.feedback 
FOR UPDATE 
USING ((SELECT auth.uid()) = user_id);

-- 12. Tablo istatistiklerini güncelle
ANALYZE public.birds;
ANALYZE public.chicks;
ANALYZE public.eggs;
ANALYZE public.incubations;
ANALYZE public.clutches;
ANALYZE public.calendar;
ANALYZE public.backup_jobs;
ANALYZE public.backup_settings;
ANALYZE public.backup_history;
ANALYZE public.user_notification_tokens;
ANALYZE public.user_notification_settings;
ANALYZE public.notification_interactions;
ANALYZE public.profiles;
ANALYZE public.photos;
ANALYZE public.feedback;

-- 13. RLS'nin aktif olduğundan emin ol
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clutches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY; 