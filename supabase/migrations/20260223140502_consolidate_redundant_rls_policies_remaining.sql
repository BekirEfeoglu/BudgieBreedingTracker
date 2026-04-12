
-- ================================================================
-- Consolidate redundant RLS policies (Part 2):
-- events, notifications, notification_schedules, photos, feedback,
-- genetics_history, calendar, event_reminders, sync_metadata, profiles
-- ================================================================

-- === EVENTS ===
DROP POLICY IF EXISTS "events: admin all" ON events;
DROP POLICY IF EXISTS "Users can insert own events" ON events;
CREATE POLICY "Users can insert own events" ON events FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can delete own events" ON events;
CREATE POLICY "Users can delete own events" ON events FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can update own events" ON events;
CREATE POLICY "Users can update own events" ON events FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === NOTIFICATIONS ===
DROP POLICY IF EXISTS "notifications: admin all" ON notifications;
DROP POLICY IF EXISTS "Users can insert own notifications" ON notifications;
CREATE POLICY "Users can insert own notifications" ON notifications FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can delete own notifications" ON notifications;
CREATE POLICY "Users can delete own notifications" ON notifications FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === NOTIFICATION_SCHEDULES ===
DROP POLICY IF EXISTS "notification_schedules: admin all" ON notification_schedules;
DROP POLICY IF EXISTS "Users can insert own schedules" ON notification_schedules;
CREATE POLICY "Users can insert own schedules" ON notification_schedules FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can delete own schedules" ON notification_schedules;
CREATE POLICY "Users can delete own schedules" ON notification_schedules FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can update own schedules" ON notification_schedules;
CREATE POLICY "Users can update own schedules" ON notification_schedules FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === PHOTOS ===
DROP POLICY IF EXISTS "photos: admin all" ON photos;
DROP POLICY IF EXISTS "Users can insert own photos" ON photos;
CREATE POLICY "Users can insert own photos" ON photos FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can delete own photos" ON photos;
CREATE POLICY "Users can delete own photos" ON photos FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can update own photos" ON photos;
CREATE POLICY "Users can update own photos" ON photos FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === FEEDBACK ===
DROP POLICY IF EXISTS "feedback: admin all" ON feedback;
DROP POLICY IF EXISTS "Users can insert own feedback" ON feedback;
CREATE POLICY "Users can insert own feedback" ON feedback FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can delete own feedback" ON feedback;
CREATE POLICY "Users can delete own feedback" ON feedback FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can update own feedback" ON feedback;
CREATE POLICY "Users can update own feedback" ON feedback FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === GENETICS_HISTORY === (SELECT also needs admin check)
DROP POLICY IF EXISTS "genetics_history: admin all" ON genetics_history;
DROP POLICY IF EXISTS "genetics_history: select own" ON genetics_history;
CREATE POLICY "genetics_history: select own" ON genetics_history FOR SELECT
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "genetics_history: insert own" ON genetics_history;
CREATE POLICY "genetics_history: insert own" ON genetics_history FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "genetics_history: delete own" ON genetics_history;
CREATE POLICY "genetics_history: delete own" ON genetics_history FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "genetics_history: update own" ON genetics_history;
CREATE POLICY "genetics_history: update own" ON genetics_history FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === CALENDAR === (Pattern B: two ALL -> one ALL)
DROP POLICY IF EXISTS "calendar: admin all" ON calendar;
DROP POLICY IF EXISTS "Users can manage own calendar" ON calendar;
CREATE POLICY "Users can manage own calendar" ON calendar FOR ALL
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === EVENT_REMINDERS === (Pattern B: two ALL -> one ALL)
DROP POLICY IF EXISTS "event_reminders: admin all" ON event_reminders;
DROP POLICY IF EXISTS "Users can manage own reminders" ON event_reminders;
CREATE POLICY "Users can manage own reminders" ON event_reminders FOR ALL
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === SYNC_METADATA === (Pattern B: two ALL -> one ALL)
DROP POLICY IF EXISTS "sync_metadata: admin all" ON sync_metadata;
DROP POLICY IF EXISTS "sync_metadata: all own" ON sync_metadata;
CREATE POLICY "sync_metadata: all own" ON sync_metadata FOR ALL
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === PROFILES === (admin ALL removed, admin check added to INSERT)
DROP POLICY IF EXISTS "profiles: admin all" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = id) OR ( SELECT is_admin()));
;
