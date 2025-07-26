-- BudgieBreedingTracker - Step 2: Indexes and RLS Policies
-- Bu dosya indexler ve RLS politikalarını oluşturur

-- 1. INDEXES (Performans için)
-- Birds indexes
CREATE INDEX IF NOT EXISTS idx_birds_user_id ON public.birds(user_id);
CREATE INDEX IF NOT EXISTS idx_birds_user_gender ON public.birds(user_id, gender);
CREATE INDEX IF NOT EXISTS idx_birds_user_birth_date ON public.birds(user_id, birth_date);
CREATE INDEX IF NOT EXISTS idx_birds_user_created_at ON public.birds(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_birds_parents ON public.birds(father_id, mother_id) WHERE father_id IS NOT NULL OR mother_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_birds_name_trigram ON public.birds USING gin(name gin_trgm_ops);

-- Incubations indexes
CREATE INDEX IF NOT EXISTS idx_incubations_user_id ON public.incubations(user_id);
CREATE INDEX IF NOT EXISTS idx_incubations_user_start_date ON public.incubations(user_id, start_date);
CREATE INDEX IF NOT EXISTS idx_incubations_user_created_at ON public.incubations(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_incubations_parents ON public.incubations(male_bird_id, female_bird_id) WHERE male_bird_id IS NOT NULL OR female_bird_id IS NOT NULL;

-- Eggs indexes
CREATE INDEX IF NOT EXISTS idx_eggs_user_id ON public.eggs(user_id);
CREATE INDEX IF NOT EXISTS idx_eggs_incubation_id ON public.eggs(incubation_id);
CREATE INDEX IF NOT EXISTS idx_eggs_user_status ON public.eggs(user_id, status);
CREATE INDEX IF NOT EXISTS idx_eggs_user_lay_date ON public.eggs(user_id, lay_date);
CREATE INDEX IF NOT EXISTS idx_eggs_incubation_status ON public.eggs(incubation_id, status);
CREATE INDEX IF NOT EXISTS idx_eggs_user_hatch_date ON public.eggs(user_id, hatch_date) WHERE hatch_date IS NOT NULL;

-- Chicks indexes
CREATE INDEX IF NOT EXISTS idx_chicks_user_id ON public.chicks(user_id);
CREATE INDEX IF NOT EXISTS idx_chicks_incubation_id ON public.chicks(incubation_id);
CREATE INDEX IF NOT EXISTS idx_chicks_user_hatch_date ON public.chicks(user_id, hatch_date);
CREATE INDEX IF NOT EXISTS idx_chicks_user_gender ON public.chicks(user_id, gender);
CREATE INDEX IF NOT EXISTS idx_chicks_incubation_hatch ON public.chicks(incubation_id, hatch_date);
CREATE INDEX IF NOT EXISTS idx_chicks_parents ON public.chicks(father_id, mother_id) WHERE father_id IS NOT NULL OR mother_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_chicks_name_trigram ON public.chicks USING gin(name gin_trgm_ops);

-- Clutches indexes
CREATE INDEX IF NOT EXISTS idx_clutches_user_id ON public.clutches(user_id);
CREATE INDEX IF NOT EXISTS idx_clutches_user_pair_date ON public.clutches(user_id, pair_date);
CREATE INDEX IF NOT EXISTS idx_clutches_user_expected_hatch ON public.clutches(user_id, expected_hatch_date) WHERE expected_hatch_date IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_clutches_birds ON public.clutches(male_bird_id, female_bird_id) WHERE male_bird_id IS NOT NULL OR female_bird_id IS NOT NULL;

-- Calendar indexes
CREATE INDEX IF NOT EXISTS idx_calendar_user_id ON public.calendar(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_event_date ON public.calendar(user_id, event_date);
CREATE INDEX IF NOT EXISTS idx_calendar_event_type ON public.calendar(user_id, event_type);

-- Photos indexes
CREATE INDEX IF NOT EXISTS idx_photos_user_id ON public.photos(user_id);
CREATE INDEX IF NOT EXISTS idx_photos_related_bird_id ON public.photos(related_bird_id) WHERE related_bird_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_photos_related_chick_id ON public.photos(related_chick_id) WHERE related_chick_id IS NOT NULL;

-- Other indexes
CREATE INDEX IF NOT EXISTS idx_backup_settings_user_id ON public.backup_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_backup_jobs_user_id ON public.backup_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_backup_history_user_id ON public.backup_history(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_user_id ON public.feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(user_id, is_read);

-- 2. UPDATED_AT TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. TRIGGERS
CREATE TRIGGER handle_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_birds_updated_at
  BEFORE UPDATE ON public.birds
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_incubations_updated_at
  BEFORE UPDATE ON public.incubations
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_eggs_updated_at
  BEFORE UPDATE ON public.eggs
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_chicks_updated_at
  BEFORE UPDATE ON public.chicks
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_clutches_updated_at
  BEFORE UPDATE ON public.clutches
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_calendar_updated_at
  BEFORE UPDATE ON public.calendar
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_backup_settings_updated_at
  BEFORE UPDATE ON public.backup_settings
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_feedback_updated_at
  BEFORE UPDATE ON public.feedback
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 4. ROW LEVEL SECURITY (RLS) ENABLE
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

-- 5. RLS POLICIES
-- Profiles policies
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Birds policies
CREATE POLICY "Users can view own birds" ON public.birds FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own birds" ON public.birds FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own birds" ON public.birds FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own birds" ON public.birds FOR DELETE USING (auth.uid() = user_id);

-- Incubations policies
CREATE POLICY "Users can view own incubations" ON public.incubations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own incubations" ON public.incubations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own incubations" ON public.incubations FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own incubations" ON public.incubations FOR DELETE USING (auth.uid() = user_id);

-- Eggs policies
CREATE POLICY "Users can view own eggs" ON public.eggs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own eggs" ON public.eggs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own eggs" ON public.eggs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own eggs" ON public.eggs FOR DELETE USING (auth.uid() = user_id);

-- Chicks policies
CREATE POLICY "Users can view own chicks" ON public.chicks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own chicks" ON public.chicks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own chicks" ON public.chicks FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own chicks" ON public.chicks FOR DELETE USING (auth.uid() = user_id);

-- Clutches policies
CREATE POLICY "Users can view own clutches" ON public.clutches FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own clutches" ON public.clutches FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own clutches" ON public.clutches FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own clutches" ON public.clutches FOR DELETE USING (auth.uid() = user_id);

-- Calendar policies
CREATE POLICY "Users can view own calendar events" ON public.calendar FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own calendar events" ON public.calendar FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own calendar events" ON public.calendar FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own calendar events" ON public.calendar FOR DELETE USING (auth.uid() = user_id);

-- Photos policies
CREATE POLICY "Users can view own photos" ON public.photos FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own photos" ON public.photos FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own photos" ON public.photos FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own photos" ON public.photos FOR DELETE USING (auth.uid() = user_id);

-- Backup settings policies
CREATE POLICY "Users can view own backup settings" ON public.backup_settings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own backup settings" ON public.backup_settings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own backup settings" ON public.backup_settings FOR UPDATE USING (auth.uid() = user_id);

-- Backup jobs policies
CREATE POLICY "Users can view own backup jobs" ON public.backup_jobs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own backup jobs" ON public.backup_jobs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own backup jobs" ON public.backup_jobs FOR UPDATE USING (auth.uid() = user_id);

-- Backup history policies
CREATE POLICY "Users can view own backup history" ON public.backup_history FOR SELECT USING (auth.uid() = user_id);

-- Feedback policies
CREATE POLICY "Users can view own feedback" ON public.feedback FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own feedback" ON public.feedback FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own feedback" ON public.feedback FOR UPDATE USING (auth.uid() = user_id);

-- Notifications policies
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own notifications" ON public.notifications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own notifications" ON public.notifications FOR DELETE USING (auth.uid() = user_id);

SELECT 'Step 2: Indexes and RLS policies created successfully' as status; 