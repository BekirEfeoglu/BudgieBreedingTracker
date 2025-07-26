-- RLS Performans Optimizasyonu
-- Bu dosya RLS politikalarını optimize eder ve performansı artırır
-- auth.uid() fonksiyonunu (select auth.uid()) ile sararak her satır için yeniden değerlendirilmesini önler

-- 1. PROFILES TABLOSU - Politikaları optimize et
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING ((select auth.uid()) = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING ((select auth.uid()) = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK ((select auth.uid()) = id);

-- 2. BIRDS TABLOSU - Politikaları optimize et
DROP POLICY IF EXISTS "Users can view own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can create own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete own birds" ON public.birds;

CREATE POLICY "Users can view own birds" ON public.birds FOR SELECT USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can create own birds" ON public.birds FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own birds" ON public.birds FOR UPDATE USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own birds" ON public.birds FOR DELETE USING ((select auth.uid()) = user_id);

-- 3. INCUBATIONS TABLOSU - Politikaları optimize et
DROP POLICY IF EXISTS "Users can view own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can create own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can update own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can delete own incubations" ON public.incubations;

CREATE POLICY "Users can view own incubations" ON public.incubations FOR SELECT USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can create own incubations" ON public.incubations FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own incubations" ON public.incubations FOR UPDATE USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own incubations" ON public.incubations FOR DELETE USING ((select auth.uid()) = user_id);

-- 4. EGGS TABLOSU - Politikaları optimize et
DROP POLICY IF EXISTS "Users can view own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can create own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can update own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can delete own eggs" ON public.eggs;

CREATE POLICY "Users can view own eggs" ON public.eggs FOR SELECT USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can create own eggs" ON public.eggs FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own eggs" ON public.eggs FOR UPDATE USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own eggs" ON public.eggs FOR DELETE USING ((select auth.uid()) = user_id);

-- 5. CHICKS TABLOSU - Politikaları optimize et
DROP POLICY IF EXISTS "Users can view own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can create own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can update own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can delete own chicks" ON public.chicks;

CREATE POLICY "Users can view own chicks" ON public.chicks FOR SELECT USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can create own chicks" ON public.chicks FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own chicks" ON public.chicks FOR UPDATE USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own chicks" ON public.chicks FOR DELETE USING ((select auth.uid()) = user_id);

-- 6. CLUTCHES TABLOSU - Politikaları optimize et
DROP POLICY IF EXISTS "Users can view own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can create own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can update own clutches" ON public.clutches;
DROP POLICY IF EXISTS "Users can delete own clutches" ON public.clutches;

CREATE POLICY "Users can view own clutches" ON public.clutches FOR SELECT USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can create own clutches" ON public.clutches FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own clutches" ON public.clutches FOR UPDATE USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own clutches" ON public.clutches FOR DELETE USING ((select auth.uid()) = user_id);

-- 7. CALENDAR TABLOSU - Politikaları optimize et
DROP POLICY IF EXISTS "Users can view own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can create own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can update own calendar events" ON public.calendar;
DROP POLICY IF EXISTS "Users can delete own calendar events" ON public.calendar;

CREATE POLICY "Users can view own calendar events" ON public.calendar FOR SELECT USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can create own calendar events" ON public.calendar FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own calendar events" ON public.calendar FOR UPDATE USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own calendar events" ON public.calendar FOR DELETE USING ((select auth.uid()) = user_id);

-- 8. PHOTOS TABLOSU - Politikaları optimize et
DROP POLICY IF EXISTS "Users can view own photos" ON public.photos;
DROP POLICY IF EXISTS "Users can create own photos" ON public.photos;
DROP POLICY IF EXISTS "Users can update own photos" ON public.photos;
DROP POLICY IF EXISTS "Users can delete own photos" ON public.photos;

CREATE POLICY "Users can view own photos" ON public.photos FOR SELECT USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can create own photos" ON public.photos FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own photos" ON public.photos FOR UPDATE USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own photos" ON public.photos FOR DELETE USING ((select auth.uid()) = user_id);

-- 9. BACKUP SETTINGS TABLOSU - Politikaları optimize et
DROP POLICY IF EXISTS "Users can view own backup settings" ON public.backup_settings;
DROP POLICY IF EXISTS "Users can create own backup settings" ON public.backup_settings;
DROP POLICY IF EXISTS "Users can update own backup settings" ON public.backup_settings;

CREATE POLICY "Users can view own backup settings" ON public.backup_settings FOR SELECT USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can create own backup settings" ON public.backup_settings FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own backup settings" ON public.backup_settings FOR UPDATE USING ((select auth.uid()) = user_id);

-- 10. BACKUP JOBS TABLOSU - Politikaları optimize et
DROP POLICY IF EXISTS "Users can view own backup jobs" ON public.backup_jobs;
DROP POLICY IF EXISTS "Users can create own backup jobs" ON public.backup_jobs;
DROP POLICY IF EXISTS "Users can update own backup jobs" ON public.backup_jobs;

CREATE POLICY "Users can view own backup jobs" ON public.backup_jobs FOR SELECT USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can create own backup jobs" ON public.backup_jobs FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own backup jobs" ON public.backup_jobs FOR UPDATE USING ((select auth.uid()) = user_id);

-- 11. BACKUP HISTORY TABLOSU - Politikaları optimize et
DROP POLICY IF EXISTS "Users can view own backup history" ON public.backup_history;

CREATE POLICY "Users can view own backup history" ON public.backup_history FOR SELECT USING ((select auth.uid()) = user_id);

-- 12. FEEDBACK TABLOSU - Politikaları optimize et
DROP POLICY IF EXISTS "Users can view own feedback" ON public.feedback;
DROP POLICY IF EXISTS "Users can create own feedback" ON public.feedback;
DROP POLICY IF EXISTS "Users can update own feedback" ON public.feedback;

CREATE POLICY "Users can view own feedback" ON public.feedback FOR SELECT USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can create own feedback" ON public.feedback FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own feedback" ON public.feedback FOR UPDATE USING ((select auth.uid()) = user_id);

-- 13. NOTIFICATIONS TABLOSU - Politikaları optimize et
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can create own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;

CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can create own notifications" ON public.notifications FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own notifications" ON public.notifications FOR DELETE USING ((select auth.uid()) = user_id);

-- 14. PERFORMANS KONTROLÜ
SELECT 
  'Performance Optimization Complete' as status,
  COUNT(*) as total_policies_optimized
FROM pg_policies 
WHERE schemaname = 'public'
  AND (qual LIKE '%(select auth.uid())%' OR with_check LIKE '%(select auth.uid())%');

-- 15. OPTIMIZE EDİLMİŞ POLİTİKALARIN LİSTESİ
SELECT 
  tablename,
  policyname,
  cmd as operation,
  CASE 
    WHEN qual LIKE '%(select auth.uid())%' OR with_check LIKE '%(select auth.uid())%' THEN '✅ Optimized'
    ELSE '❌ Not Optimized'
  END as optimization_status
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, cmd;

SELECT 'RLS performans optimizasyonu tamamlandı! Tüm politikalar artık optimize edildi.' as final_status; 