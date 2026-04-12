
-- Fix 4b: Replace auth.uid() with (select auth.uid()) for events, calendar, notifications

-- ========== EVENTS ==========
DROP POLICY IF EXISTS "Users can view own events" ON events;
DROP POLICY IF EXISTS "Users can insert own events" ON events;
DROP POLICY IF EXISTS "Users can update own events" ON events;
DROP POLICY IF EXISTS "Users can delete own events" ON events;

CREATE POLICY "Users can view own events" ON events FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can insert own events" ON events FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own events" ON events FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own events" ON events FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== EVENT_TYPES ==========
DROP POLICY IF EXISTS "Users can view system and own event types" ON event_types;
DROP POLICY IF EXISTS "Users can manage own event types" ON event_types;
DROP POLICY IF EXISTS "Users can update own event types" ON event_types;
DROP POLICY IF EXISTS "Users can delete own event types" ON event_types;

CREATE POLICY "Users can view system and own event types" ON event_types FOR SELECT TO authenticated
  USING (is_system = true OR (select auth.uid()) = user_id);
CREATE POLICY "Users can manage own event types" ON event_types FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id AND is_system = false);
CREATE POLICY "Users can update own event types" ON event_types FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id AND is_system = false);
CREATE POLICY "Users can delete own event types" ON event_types FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id AND is_system = false);

-- ========== EVENT_TEMPLATES ==========
DROP POLICY IF EXISTS "Users can view system and own templates" ON event_templates;
DROP POLICY IF EXISTS "Users can manage own templates" ON event_templates;
DROP POLICY IF EXISTS "Users can update own templates" ON event_templates;
DROP POLICY IF EXISTS "Users can delete own templates" ON event_templates;

CREATE POLICY "Users can view system and own templates" ON event_templates FOR SELECT TO authenticated
  USING (is_system = true OR (select auth.uid()) = user_id);
CREATE POLICY "Users can manage own templates" ON event_templates FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id AND is_system = false);
CREATE POLICY "Users can update own templates" ON event_templates FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id AND is_system = false);
CREATE POLICY "Users can delete own templates" ON event_templates FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id AND is_system = false);

-- ========== EVENT_REMINDERS ==========
DROP POLICY IF EXISTS "Users can manage own reminders" ON event_reminders;
CREATE POLICY "Users can manage own reminders" ON event_reminders FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== CALENDAR ==========
DROP POLICY IF EXISTS "Users can manage own calendar" ON calendar;
CREATE POLICY "Users can manage own calendar" ON calendar FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== NOTIFICATIONS ==========
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can insert own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON notifications;

CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can insert own notifications" ON notifications FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own notifications" ON notifications FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== NOTIFICATION_SETTINGS ==========
DROP POLICY IF EXISTS "Users can view own notification_settings" ON notification_settings;
DROP POLICY IF EXISTS "Users can insert own notification_settings" ON notification_settings;
DROP POLICY IF EXISTS "Users can update own notification_settings" ON notification_settings;
DROP POLICY IF EXISTS "Users can delete own notification_settings" ON notification_settings;

CREATE POLICY "Users can view own notification_settings" ON notification_settings FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can insert own notification_settings" ON notification_settings FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own notification_settings" ON notification_settings FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own notification_settings" ON notification_settings FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== NOTIFICATION_SCHEDULES ==========
DROP POLICY IF EXISTS "Users can manage own schedules" ON notification_schedules;
CREATE POLICY "Users can manage own schedules" ON notification_schedules FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== NOTIFICATION_HISTORY ==========
DROP POLICY IF EXISTS "Users can view own history" ON notification_history;
CREATE POLICY "Users can view own history" ON notification_history FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== NOTIFICATION_RATE_LIMITS ==========
DROP POLICY IF EXISTS "Users can view own rate limits" ON notification_rate_limits;
CREATE POLICY "Users can view own rate limits" ON notification_rate_limits FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== FCM_TOKENS ==========
DROP POLICY IF EXISTS "Users can manage own tokens" ON fcm_tokens;
CREATE POLICY "Users can manage own tokens" ON fcm_tokens FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== WEB_PUSH_SUBSCRIPTIONS ==========
DROP POLICY IF EXISTS "Users can manage own subscriptions" ON web_push_subscriptions;
CREATE POLICY "Users can manage own subscriptions" ON web_push_subscriptions FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);
;
