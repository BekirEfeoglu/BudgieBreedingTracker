
-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE breeding_pairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE growth_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;

-- Profiles: users can only access their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Birds
CREATE POLICY "Users can view own birds"
  ON birds FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own birds"
  ON birds FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own birds"
  ON birds FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own birds"
  ON birds FOR DELETE
  USING (auth.uid() = user_id);

-- Breeding pairs
CREATE POLICY "Users can view own breeding_pairs"
  ON breeding_pairs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own breeding_pairs"
  ON breeding_pairs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own breeding_pairs"
  ON breeding_pairs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own breeding_pairs"
  ON breeding_pairs FOR DELETE
  USING (auth.uid() = user_id);

-- Incubations
CREATE POLICY "Users can view own incubations"
  ON incubations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own incubations"
  ON incubations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own incubations"
  ON incubations FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own incubations"
  ON incubations FOR DELETE
  USING (auth.uid() = user_id);

-- Eggs
CREATE POLICY "Users can view own eggs"
  ON eggs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own eggs"
  ON eggs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own eggs"
  ON eggs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own eggs"
  ON eggs FOR DELETE
  USING (auth.uid() = user_id);

-- Chicks
CREATE POLICY "Users can view own chicks"
  ON chicks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own chicks"
  ON chicks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own chicks"
  ON chicks FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own chicks"
  ON chicks FOR DELETE
  USING (auth.uid() = user_id);

-- Health records
CREATE POLICY "Users can view own health_records"
  ON health_records FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own health_records"
  ON health_records FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own health_records"
  ON health_records FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own health_records"
  ON health_records FOR DELETE
  USING (auth.uid() = user_id);

-- Growth measurements
CREATE POLICY "Users can view own growth_measurements"
  ON growth_measurements FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own growth_measurements"
  ON growth_measurements FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own growth_measurements"
  ON growth_measurements FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own growth_measurements"
  ON growth_measurements FOR DELETE
  USING (auth.uid() = user_id);

-- Events
CREATE POLICY "Users can view own events"
  ON events FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own events"
  ON events FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own events"
  ON events FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own events"
  ON events FOR DELETE
  USING (auth.uid() = user_id);

-- Notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notifications"
  ON notifications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

-- Notification settings
CREATE POLICY "Users can view own notification_settings"
  ON notification_settings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification_settings"
  ON notification_settings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notification_settings"
  ON notification_settings FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notification_settings"
  ON notification_settings FOR DELETE
  USING (auth.uid() = user_id);
;
