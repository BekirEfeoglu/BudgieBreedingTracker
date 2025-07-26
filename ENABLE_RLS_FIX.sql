-- Supabase RLS Güvenlik Düzeltmesi
-- Bu dosya tüm tablolarda RLS'yi etkinleştirir ve gerekli politikaları oluşturur

-- 1. ROW LEVEL SECURITY (RLS) ENABLE - Tüm tablolarda RLS'yi etkinleştir
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clutches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 2. RLS POLICIES - Tüm tablolar için güvenlik politikaları oluştur

-- Profiles policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Birds policies
DROP POLICY IF EXISTS "Users can view own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can create own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete own birds" ON public.birds;

CREATE POLICY "Users can view own birds" ON public.birds FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own birds" ON public.birds FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own birds" ON public.birds FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own birds" ON public.birds FOR DELETE USING (auth.uid() = user_id);

-- Incubations policies
DROP POLICY IF EXISTS "Users can view own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can create own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can update own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can delete own incubations" ON public.incubations;

CREATE POLICY "Users can view own incubations" ON public.incubations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own incubations" ON public.incubations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own incubations" ON public.incubations FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own incubations" ON public.incubations FOR DELETE USING (auth.uid() = user_id);

-- Eggs policies
DROP POLICY IF EXISTS "Users can view own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can create own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can update own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can delete own eggs" ON public.eggs;

CREATE POLICY "Users can view own eggs" ON public.eggs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own eggs" ON public.eggs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own eggs" ON public.eggs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own eggs" ON public.eggs FOR DELETE USING (auth.uid() = user_id);

-- Chicks policies
DROP POLICY IF EXISTS "Users can view own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can create own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can update own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can delete own chicks" ON public.chicks;

CREATE POLICY "Users can view own chicks" ON public.chicks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own chicks" ON public.chicks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own chicks" ON public.chicks FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own chicks" ON public.chicks FOR DELETE USING (auth.uid() = user_id);

-- Clutches policies
DROP POLICY IF EXISTS "Users can view own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can create own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can update own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can delete own clutches" ON public.clutches;

CREATE POLICY "Users can view own clutches" ON public.clutches FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own clutches" ON public.clutches FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own clutches" ON public.clutches FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own clutches" ON public.clutches FOR DELETE USING (auth.uid() = user_id);

-- Calendar policies
DROP POLICY IF EXISTS "Users can view own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can create own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can update own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can delete own calendar events" ON public.calendar;

CREATE POLICY "Users can view own calendar events" ON public.calendar FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own calendar events" ON public.calendar FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own calendar events" ON public.calendar FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own calendar events" ON public.calendar FOR DELETE USING (auth.uid() = user_id);

-- Photos policies
DROP POLICY IF EXISTS "Users can view own photos" ON public.photos;
DROP POLICY IF EXISTS "Users can create own photos" ON public.photos;
DROP POLICY IF EXISTS "Users can update own photos" ON public.photos;
DROP POLICY IF EXISTS "Users can delete own photos" ON public.photos;

CREATE POLICY "Users can view own photos" ON public.photos FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own photos" ON public.photos FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own photos" ON public.photos FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own photos" ON public.photos FOR DELETE USING (auth.uid() = user_id);

-- Backup settings policies
DROP POLICY IF EXISTS "Users can view own backup settings" ON public.backup_settings;
DROP POLICY IF EXISTS "Users can create own backup settings" ON public.backup_settings;
DROP POLICY IF EXISTS "Users can update own backup settings" ON public.backup_settings;

CREATE POLICY "Users can view own backup settings" ON public.backup_settings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own backup settings" ON public.backup_settings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own backup settings" ON public.backup_settings FOR UPDATE USING (auth.uid() = user_id);

-- Backup jobs policies
DROP POLICY IF EXISTS "Users can view own backup jobs" ON public.backup_jobs;
DROP POLICY IF EXISTS "Users can create own backup jobs" ON public.backup_jobs;
DROP POLICY IF EXISTS "Users can update own backup jobs" ON public.backup_jobs;

CREATE POLICY "Users can view own backup jobs" ON public.backup_jobs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own backup jobs" ON public.backup_jobs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own backup jobs" ON public.backup_jobs FOR UPDATE USING (auth.uid() = user_id);

-- Backup history policies
DROP POLICY IF EXISTS "Users can view own backup history" ON public.backup_history;

CREATE POLICY "Users can view own backup history" ON public.backup_history FOR SELECT USING (auth.uid() = user_id);

-- Feedback policies
DROP POLICY IF EXISTS "Users can view own feedback" ON public.feedback;
DROP POLICY IF EXISTS "Users can create own feedback" ON public.feedback;
DROP POLICY IF EXISTS "Users can update own feedback" ON public.feedback;

CREATE POLICY "Users can view own feedback" ON public.feedback FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own feedback" ON public.feedback FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own feedback" ON public.feedback FOR UPDATE USING (auth.uid() = user_id);

-- Notifications policies
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can create own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;

CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own notifications" ON public.notifications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own notifications" ON public.notifications FOR DELETE USING (auth.uid() = user_id);

-- 3. RLS DURUMUNU KONTROL ET
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled,
  CASE 
    WHEN rowsecurity THEN '✅ RLS Enabled'
    ELSE '❌ RLS Disabled'
  END as status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'profiles', 'birds', 'incubations', 'eggs', 'chicks', 
    'clutches', 'calendar', 'photos', 'backup_settings', 
    'backup_jobs', 'backup_history', 'feedback', 'notifications'
  )
ORDER BY tablename;

-- 4. POLICY SAYISINI KONTROL ET
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

SELECT 'RLS güvenlik düzeltmesi tamamlandı! Tüm tablolar artık güvenli.' as status; 