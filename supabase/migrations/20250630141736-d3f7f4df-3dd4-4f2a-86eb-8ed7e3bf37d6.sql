
-- Mevcut RLS politikalarını kaldır ve optimize edilmiş versiyonlarını oluştur

-- Birds tablosu için optimize edilmiş politikalar
DROP POLICY IF EXISTS "Users can view their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can create their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete their own birds" ON public.birds;

CREATE POLICY "Users can view their own birds" 
  ON public.birds 
  FOR SELECT 
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create their own birds" 
  ON public.birds 
  FOR INSERT 
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own birds" 
  ON public.birds 
  FOR UPDATE 
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own birds" 
  ON public.birds 
  FOR DELETE 
  USING ((SELECT auth.uid()) = user_id);

-- Chicks tablosu için optimize edilmiş politikalar
DROP POLICY IF EXISTS "Users can view their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can create their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can update their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can delete their own chicks" ON public.chicks;

CREATE POLICY "Users can view their own chicks" 
  ON public.chicks 
  FOR SELECT 
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create their own chicks" 
  ON public.chicks 
  FOR INSERT 
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own chicks" 
  ON public.chicks 
  FOR UPDATE 
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own chicks" 
  ON public.chicks 
  FOR DELETE 
  USING ((SELECT auth.uid()) = user_id);

-- Clutches tablosu için optimize edilmiş politikalar
DROP POLICY IF EXISTS "Users can view their own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can create their own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can update their own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can delete their own clutches" ON public.clutches;

CREATE POLICY "Users can view their own clutches" 
  ON public.clutches 
  FOR SELECT 
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create their own clutches" 
  ON public.clutches 
  FOR INSERT 
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own clutches" 
  ON public.clutches 
  FOR UPDATE 
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own clutches" 
  ON public.clutches 
  FOR DELETE 
  USING ((SELECT auth.uid()) = user_id);

-- Eggs tablosu için optimize edilmiş politikalar
DROP POLICY IF EXISTS "Users can view their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can create their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can update their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can delete their own eggs" ON public.eggs;

CREATE POLICY "Users can view their own eggs" 
  ON public.eggs 
  FOR SELECT 
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create their own eggs" 
  ON public.eggs 
  FOR INSERT 
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own eggs" 
  ON public.eggs 
  FOR UPDATE 
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own eggs" 
  ON public.eggs 
  FOR DELETE 
  USING ((SELECT auth.uid()) = user_id);

-- Calendar tablosu için optimize edilmiş politikalar (çakışan politikaları temizle)
DROP POLICY IF EXISTS "Users can view their own calendar" ON public.calendar;
DROP POLICY IF EXISTS "Users can view their own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can create their own calendar" ON public.calendar;
DROP POLICY IF EXISTS "Users can create their own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can update their own calendar" ON public.calendar;
DROP POLICY IF EXISTS "Users can update their own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can delete their own calendar" ON public.calendar;
DROP POLICY IF EXISTS "Users can delete their own calendar events" ON public.calendar;

CREATE POLICY "Users can view their own calendar events" 
  ON public.calendar 
  FOR SELECT 
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create their own calendar events" 
  ON public.calendar 
  FOR INSERT 
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own calendar events" 
  ON public.calendar 
  FOR UPDATE 
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own calendar events" 
  ON public.calendar 
  FOR DELETE 
  USING ((SELECT auth.uid()) = user_id);

-- Backup Jobs tablosu için optimize edilmiş politikalar
DROP POLICY IF EXISTS "Users can view their own backup jobs" ON public.backup_jobs;
DROP POLICY IF EXISTS "Users can create their own backup jobs" ON public.backup_jobs;
DROP POLICY IF EXISTS "Users can update their own backup jobs" ON public.backup_jobs;

CREATE POLICY "Users can view their own backup jobs" 
  ON public.backup_jobs 
  FOR SELECT 
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create their own backup jobs" 
  ON public.backup_jobs 
  FOR INSERT 
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own backup jobs" 
  ON public.backup_jobs 
  FOR UPDATE 
  USING ((SELECT auth.uid()) = user_id);

-- Backup Settings tablosu için optimize edilmiş politikalar
DROP POLICY IF EXISTS "Users can view their own backup settings" ON public.backup_settings;
DROP POLICY IF EXISTS "Users can create their own backup settings" ON public.backup_settings;
DROP POLICY IF EXISTS "Users can update their own backup settings" ON public.backup_settings;

CREATE POLICY "Users can view their own backup settings" 
  ON public.backup_settings 
  FOR SELECT 
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create their own backup settings" 
  ON public.backup_settings 
  FOR INSERT 
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own backup settings" 
  ON public.backup_settings 
  FOR UPDATE 
  USING ((SELECT auth.uid()) = user_id);

-- Backup History tablosu için optimize edilmiş politikalar
DROP POLICY IF EXISTS "Users can view their own backup history" ON public.backup_history;

CREATE POLICY "Users can view their own backup history" 
  ON public.backup_history 
  FOR SELECT 
  USING ((SELECT auth.uid()) = user_id);
