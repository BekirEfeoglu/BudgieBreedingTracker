
-- ============================================================
-- SORUN 1: UPDATE with_check eksik olan tablolar
-- Kullanıcıların user_id'yi değiştiremesini engelle
-- ============================================================

-- birds: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own birds" ON public.birds;
CREATE POLICY "Users can update own birds" ON public.birds
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- breeding_pairs: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own breeding_pairs" ON public.breeding_pairs;
CREATE POLICY "Users can update own breeding_pairs" ON public.breeding_pairs
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- chicks: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own chicks" ON public.chicks;
CREATE POLICY "Users can update own chicks" ON public.chicks
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- eggs: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own eggs" ON public.eggs;
CREATE POLICY "Users can update own eggs" ON public.eggs
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- events: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own events" ON public.events;
CREATE POLICY "Users can update own events" ON public.events
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- health_records: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own health_records" ON public.health_records;
CREATE POLICY "Users can update own health_records" ON public.health_records
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- growth_measurements: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own growth_measurements" ON public.growth_measurements;
CREATE POLICY "Users can update own growth_measurements" ON public.growth_measurements
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- incubations: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own incubations" ON public.incubations;
CREATE POLICY "Users can update own incubations" ON public.incubations
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- notification_settings: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own notification_settings" ON public.notification_settings;
CREATE POLICY "Users can update own notification_settings" ON public.notification_settings
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- feedback: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own feedback" ON public.feedback;
CREATE POLICY "Users can update own feedback" ON public.feedback
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- community_comments: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own comments" ON public.community_comments;
CREATE POLICY "Users can update own comments" ON public.community_comments
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- community_events: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own events" ON public.community_events;
CREATE POLICY "Users can update own events" ON public.community_events
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- community_stories: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own stories" ON public.community_stories;
CREATE POLICY "Users can update own stories" ON public.community_stories
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- community_posts: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own posts" ON public.community_posts;
CREATE POLICY "Users can update own posts" ON public.community_posts
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- user_sessions: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own sessions" ON public.user_sessions;
CREATE POLICY "Users can update own sessions" ON public.user_sessions
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- notification_rate_limits: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own rate limits" ON public.notification_rate_limits;
CREATE POLICY "Users can update own rate limits" ON public.notification_rate_limits
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- notification_history: DELETE var, INSERT var, SELECT var ama UPDATE yok
-- UPDATE ekle
CREATE POLICY "Users can update own notification history" ON public.notification_history
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- event_templates: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own templates" ON public.event_templates;
CREATE POLICY "Users can update own templates" ON public.event_templates
  FOR UPDATE TO authenticated
  USING (((SELECT auth.uid()) = user_id) AND (is_system = false))
  WITH CHECK (((SELECT auth.uid()) = user_id) AND (is_system = false));

-- event_types: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Users can update own event types" ON public.event_types;
CREATE POLICY "Users can update own event types" ON public.event_types
  FOR UPDATE TO authenticated
  USING (((SELECT auth.uid()) = user_id) AND (is_system = false))
  WITH CHECK (((SELECT auth.uid()) = user_id) AND (is_system = false));

-- admin_rate_limits: UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Admins can update own rate limits" ON public.admin_rate_limits;
CREATE POLICY "Admins can update own rate limits" ON public.admin_rate_limits
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = admin_user_id)
  WITH CHECK ((SELECT auth.uid()) = admin_user_id);

-- error_logs: admin UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Admins can update error logs" ON public.error_logs;
CREATE POLICY "Admins can update error logs" ON public.error_logs
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users))
  WITH CHECK ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users));

-- system_settings: admin UPDATE with_check eklenmeli
DROP POLICY IF EXISTS "Admins can update settings" ON public.system_settings;
CREATE POLICY "Admins can update settings" ON public.system_settings
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users))
  WITH CHECK ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users));

-- ============================================================
-- SORUN 2: Admin SELECT erişimi eksik tablolar
-- ============================================================

-- eggs: admin'ler de görebilmeli
DROP POLICY IF EXISTS "Users can view own eggs" ON public.eggs;
CREATE POLICY "Users can view own eggs" ON public.eggs
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users)));

-- chicks: admin'ler de görebilmeli
DROP POLICY IF EXISTS "Users can view own chicks" ON public.chicks;
CREATE POLICY "Users can view own chicks" ON public.chicks
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users)));

-- health_records: admin'ler de görebilmeli
DROP POLICY IF EXISTS "Users can view own health_records" ON public.health_records;
CREATE POLICY "Users can view own health_records" ON public.health_records
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users)));

-- growth_measurements: admin'ler de görebilmeli
DROP POLICY IF EXISTS "Users can view own growth_measurements" ON public.growth_measurements;
CREATE POLICY "Users can view own growth_measurements" ON public.growth_measurements
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users)));

-- events: admin'ler de görebilmeli
DROP POLICY IF EXISTS "Users can view own events" ON public.events;
CREATE POLICY "Users can view own events" ON public.events
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users)));

-- incubations: admin'ler de görebilmeli
DROP POLICY IF EXISTS "Users can view own incubations" ON public.incubations;
CREATE POLICY "Users can view own incubations" ON public.incubations
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users)));

-- clutches: admin'ler de görebilmeli (mevcut ALL policy drop & ayrı ayrı oluştur)
DROP POLICY IF EXISTS "Users can manage own clutches" ON public.clutches;
CREATE POLICY "Users can view own clutches" ON public.clutches
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users)));
CREATE POLICY "Users can insert own clutches" ON public.clutches
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can update own clutches" ON public.clutches
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can delete own clutches" ON public.clutches
  FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- nests: admin'ler de görebilmeli
DROP POLICY IF EXISTS "Users can manage own nests" ON public.nests;
CREATE POLICY "Users can view own nests" ON public.nests
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users)));
CREATE POLICY "Users can insert own nests" ON public.nests
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can update own nests" ON public.nests
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can delete own nests" ON public.nests
  FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- photos: admin'ler de görebilmeli
DROP POLICY IF EXISTS "Users can manage own photos" ON public.photos;
CREATE POLICY "Users can view own photos" ON public.photos
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users)));
CREATE POLICY "Users can insert own photos" ON public.photos
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can update own photos" ON public.photos
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can delete own photos" ON public.photos
  FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- notifications: admin'ler de görebilmeli
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications" ON public.notifications
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users)));

-- notification_settings: admin'ler de görebilmeli
DROP POLICY IF EXISTS "Users can view own notification_settings" ON public.notification_settings;
CREATE POLICY "Users can view own notification_settings" ON public.notification_settings
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users)));

-- notification_history: admin'ler de görebilmeli
DROP POLICY IF EXISTS "Users can view own history" ON public.notification_history;
CREATE POLICY "Users can view own history" ON public.notification_history
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users)));

-- notification_schedules: admin'ler de görebilmeli
DROP POLICY IF EXISTS "Users can manage own schedules" ON public.notification_schedules;
CREATE POLICY "Users can view own schedules" ON public.notification_schedules
  FOR SELECT TO authenticated
  USING (((SELECT auth.uid()) = user_id) OR ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users)));
CREATE POLICY "Users can insert own schedules" ON public.notification_schedules
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can update own schedules" ON public.notification_schedules
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can delete own schedules" ON public.notification_schedules
  FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- ============================================================
-- SORUN 3: notification_rate_limits DELETE eksik
-- ============================================================
CREATE POLICY "Users can delete own rate limits" ON public.notification_rate_limits
  FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- ============================================================
-- SORUN 5: community_polls UPDATE eksik
-- ============================================================
CREATE POLICY "Post owners can update polls" ON public.community_polls
  FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM community_posts
    WHERE community_posts.id = community_polls.post_id
      AND community_posts.user_id = (SELECT auth.uid())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM community_posts
    WHERE community_posts.id = community_polls.post_id
      AND community_posts.user_id = (SELECT auth.uid())
  ));

-- ============================================================
-- SORUN 6: community_poll_options UPDATE/DELETE eksik
-- ============================================================
CREATE POLICY "Post owners can update poll options" ON public.community_poll_options
  FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM community_polls cp
    JOIN community_posts cpost ON cpost.id = cp.post_id
    WHERE cp.id = community_poll_options.poll_id
      AND cpost.user_id = (SELECT auth.uid())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM community_polls cp
    JOIN community_posts cpost ON cpost.id = cp.post_id
    WHERE cp.id = community_poll_options.poll_id
      AND cpost.user_id = (SELECT auth.uid())
  ));

CREATE POLICY "Post owners can delete poll options" ON public.community_poll_options
  FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM community_polls cp
    JOIN community_posts cpost ON cpost.id = cp.post_id
    WHERE cp.id = community_poll_options.poll_id
      AND cpost.user_id = (SELECT auth.uid())
  ));

-- ============================================================
-- SORUN 7: system_status normal kullanıcılar için SELECT
-- ============================================================
CREATE POLICY "Users can view system status" ON public.system_status
  FOR SELECT TO authenticated
  USING (true);

-- ============================================================
-- SORUN 8: community_event_attendees UPDATE eksik
-- ============================================================
CREATE POLICY "Users can update own attendance" ON public.community_event_attendees
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================================
-- notifications UPDATE with_check eklenmeli
-- ============================================================
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications" ON public.notifications
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);
;
