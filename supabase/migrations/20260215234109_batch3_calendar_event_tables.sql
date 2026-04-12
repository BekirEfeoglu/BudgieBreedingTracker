
-- =============================================
-- BATCH 3: Takvim & Etkinlikler
-- =============================================

-- 1. Calendar (Genel takvim etkinlikleri)
CREATE TABLE calendar (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  event_date timestamptz NOT NULL,
  end_date timestamptz,
  all_day boolean NOT NULL DEFAULT false,
  color text,
  icon text,
  recurrence text CHECK (recurrence IN ('none', 'daily', 'weekly', 'monthly', 'yearly')),
  recurrence_end_date timestamptz,
  entity_type text,
  entity_id uuid,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  is_deleted boolean NOT NULL DEFAULT false
);

CREATE INDEX idx_calendar_user_id ON calendar(user_id);
CREATE INDEX idx_calendar_event_date ON calendar(event_date);
CREATE INDEX idx_calendar_entity ON calendar(entity_type, entity_id);

ALTER TABLE calendar ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own calendar" ON calendar
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 2. Event Types (Etkinlik kategorileri)
CREATE TABLE event_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  color text NOT NULL DEFAULT '#2196F3',
  icon text NOT NULL DEFAULT 'event',
  is_system boolean NOT NULL DEFAULT false,
  is_active boolean NOT NULL DEFAULT true,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_event_types_user_id ON event_types(user_id);

ALTER TABLE event_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view system and own event types" ON event_types
  FOR SELECT USING (is_system = true OR auth.uid() = user_id);
CREATE POLICY "Users can manage own event types" ON event_types
  FOR INSERT WITH CHECK (auth.uid() = user_id AND is_system = false);
CREATE POLICY "Users can update own event types" ON event_types
  FOR UPDATE USING (auth.uid() = user_id AND is_system = false);
CREATE POLICY "Users can delete own event types" ON event_types
  FOR DELETE USING (auth.uid() = user_id AND is_system = false);

-- Insert system event types
INSERT INTO event_types (name, color, icon, is_system, sort_order) VALUES
  ('Yumurtlama', '#FF9800', 'egg', true, 0),
  ('Kuluçka', '#F44336', 'thermostat', true, 1),
  ('Çıkış', '#4CAF50', 'celebration', true, 2),
  ('Sütten Kesme', '#2196F3', 'restaurant', true, 3),
  ('Sağlık Kontrolü', '#9C27B0', 'medical_services', true, 4),
  ('Veteriner', '#E91E63', 'local_hospital', true, 5),
  ('Eşleştirme', '#FF5722', 'favorite', true, 6),
  ('Genel', '#607D8B', 'event', true, 7);

-- 3. Event Templates (Şablon etkinlikler)
CREATE TABLE event_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type_id uuid REFERENCES event_types(id) ON DELETE SET NULL,
  name text NOT NULL,
  title_template text NOT NULL,
  description_template text,
  duration_minutes int,
  default_reminder_minutes int DEFAULT 30,
  is_system boolean NOT NULL DEFAULT false,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_event_templates_user_id ON event_templates(user_id);

ALTER TABLE event_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view system and own templates" ON event_templates
  FOR SELECT USING (is_system = true OR auth.uid() = user_id);
CREATE POLICY "Users can manage own templates" ON event_templates
  FOR INSERT WITH CHECK (auth.uid() = user_id AND is_system = false);
CREATE POLICY "Users can update own templates" ON event_templates
  FOR UPDATE USING (auth.uid() = user_id AND is_system = false);
CREATE POLICY "Users can delete own templates" ON event_templates
  FOR DELETE USING (auth.uid() = user_id AND is_system = false);

-- 4. Event Reminders (Bildirim zamanlamaları)
CREATE TABLE event_reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_id uuid REFERENCES events(id) ON DELETE CASCADE,
  calendar_id uuid REFERENCES calendar(id) ON DELETE CASCADE,
  reminder_type text NOT NULL DEFAULT 'notification' CHECK (reminder_type IN ('notification', 'email', 'push', 'sms')),
  minutes_before int NOT NULL DEFAULT 30,
  is_sent boolean NOT NULL DEFAULT false,
  sent_at timestamptz,
  scheduled_at timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_event_reminders_user_id ON event_reminders(user_id);
CREATE INDEX idx_event_reminders_scheduled ON event_reminders(scheduled_at, is_sent);
CREATE INDEX idx_event_reminders_event_id ON event_reminders(event_id);

ALTER TABLE event_reminders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own reminders" ON event_reminders
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
;
