-- BudgieBreedingTracker - Complete Database Schema with RLS
-- Bu migration dosyası tüm tabloları sırasıyla oluşturur ve RLS politikalarını ayarlar

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 2. PROFILES TABLOSU (Kullanıcı profilleri)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 3. BIRDS TABLOSU (Muhabbet kuşları)
CREATE TABLE IF NOT EXISTS public.birds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  gender TEXT CHECK (gender IN ('male', 'female', 'unknown')) NOT NULL DEFAULT 'unknown',
  color TEXT,
  birth_date DATE,
  ring_number TEXT,
  photo_url TEXT,
  health_notes TEXT,
  mother_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  father_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 4. INCUBATIONS TABLOSU (Kuluçka dönemleri)
CREATE TABLE IF NOT EXISTS public.incubations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  female_bird_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  male_bird_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 5. EGGS TABLOSU (Yumurtalar)
CREATE TABLE IF NOT EXISTS public.eggs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  incubation_id UUID NOT NULL REFERENCES public.incubations(id) ON DELETE CASCADE,
  lay_date DATE NOT NULL,
  status TEXT CHECK (status IN ('laid', 'fertile', 'hatched', 'infertile')) NOT NULL DEFAULT 'laid',
  hatch_date DATE,
  notes TEXT,
  chick_id UUID, -- Circular reference için NULL olarak bırakıyoruz
  number INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 6. CHICKS TABLOSU (Yavrular)
CREATE TABLE IF NOT EXISTS public.chicks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  gender TEXT CHECK (gender IN ('male', 'female', 'unknown')) NOT NULL DEFAULT 'unknown',
  color TEXT,
  hatch_date DATE NOT NULL,
  ring_number TEXT,
  photo_url TEXT,
  health_notes TEXT,
  mother_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  father_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  incubation_id UUID NOT NULL REFERENCES public.incubations(id) ON DELETE CASCADE,
  egg_id UUID REFERENCES public.eggs(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 7. CLUTCHES TABLOSU (Kuluçka çiftleri)
CREATE TABLE IF NOT EXISTS public.clutches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  male_bird_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  female_bird_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  pair_date DATE NOT NULL,
  expected_hatch_date DATE,
  notes TEXT,
  status TEXT CHECK (status IN ('active', 'completed', 'cancelled')) NOT NULL DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 8. CALENDAR TABLOSU (Takvim olayları)
CREATE TABLE IF NOT EXISTS public.calendar (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  event_date DATE NOT NULL,
  event_type TEXT CHECK (event_type IN ('breeding', 'hatching', 'health', 'feeding', 'other')) NOT NULL,
  related_bird_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  related_chick_id UUID REFERENCES public.chicks(id) ON DELETE SET NULL,
  related_incubation_id UUID REFERENCES public.incubations(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 9. PHOTOS TABLOSU (Fotoğraflar)
CREATE TABLE IF NOT EXISTS public.photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  filename TEXT NOT NULL,
  file_size INTEGER,
  mime_type TEXT,
  related_bird_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  related_chick_id UUID REFERENCES public.chicks(id) ON DELETE SET NULL,
  related_incubation_id UUID REFERENCES public.incubations(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 10. BACKUP SETTINGS TABLOSU (Yedekleme ayarları)
CREATE TABLE IF NOT EXISTS public.backup_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  auto_backup_enabled BOOLEAN DEFAULT false,
  backup_frequency TEXT CHECK (backup_frequency IN ('daily', 'weekly', 'monthly')) DEFAULT 'weekly',
  last_backup_date TIMESTAMP WITH TIME ZONE,
  backup_location TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 11. BACKUP JOBS TABLOSU (Yedekleme işleri)
CREATE TABLE IF NOT EXISTS public.backup_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('pending', 'running', 'completed', 'failed')) NOT NULL DEFAULT 'pending',
  backup_type TEXT CHECK (backup_type IN ('manual', 'auto')) NOT NULL DEFAULT 'manual',
  file_size INTEGER,
  file_url TEXT,
  error_message TEXT,
  started_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 12. BACKUP HISTORY TABLOSU (Yedekleme geçmişi)
CREATE TABLE IF NOT EXISTS public.backup_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  backup_job_id UUID REFERENCES public.backup_jobs(id) ON DELETE SET NULL,
  backup_date TIMESTAMP WITH TIME ZONE NOT NULL,
  file_size INTEGER,
  file_url TEXT,
  status TEXT CHECK (status IN ('success', 'failed')) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 13. FEEDBACK TABLOSU (Geri bildirimler)
CREATE TABLE IF NOT EXISTS public.feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject TEXT NOT NULL,
  message TEXT NOT NULL,
  category TEXT CHECK (category IN ('bug', 'feature', 'general', 'support')) NOT NULL DEFAULT 'general',
  status TEXT CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')) NOT NULL DEFAULT 'open',
  priority TEXT CHECK (priority IN ('low', 'medium', 'high', 'urgent')) NOT NULL DEFAULT 'medium',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 14. NOTIFICATIONS TABLOSU (Bildirimler)
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT CHECK (type IN ('info', 'warning', 'error', 'success')) NOT NULL DEFAULT 'info',
  is_read BOOLEAN DEFAULT false,
  related_bird_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
  related_chick_id UUID REFERENCES public.chicks(id) ON DELETE SET NULL,
  related_incubation_id UUID REFERENCES public.incubations(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 15. INDEXES (Performans için)
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

-- 16. UPDATED_AT TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 17. TRIGGERS
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

-- 18. ROW LEVEL SECURITY (RLS) ENABLE
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

-- 19. RLS POLICIES
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

-- 20. SUPABASE REALTIME SETUP
-- Publication oluştur
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    CREATE PUBLICATION supabase_realtime FOR ALL TABLES;
  END IF;
END
$$;

-- Tabloları publication'a ekle
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.birds;
ALTER PUBLICATION supabase_realtime ADD TABLE public.incubations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.eggs;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chicks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.clutches;
ALTER PUBLICATION supabase_realtime ADD TABLE public.calendar;
ALTER PUBLICATION supabase_realtime ADD TABLE public.photos;
ALTER PUBLICATION supabase_realtime ADD TABLE public.backup_settings;
ALTER PUBLICATION supabase_realtime ADD TABLE public.backup_jobs;
ALTER PUBLICATION supabase_realtime ADD TABLE public.backup_history;
ALTER PUBLICATION supabase_realtime ADD TABLE public.feedback;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- 21. UTILITY FUNCTIONS
-- Genealogy function
CREATE OR REPLACE FUNCTION public.get_bird_family(bird_id uuid, user_id uuid)
RETURNS TABLE(
  relation_type text,
  bird_id uuid,
  bird_name text,
  bird_gender text,
  is_chick boolean
) AS $$
BEGIN
  RETURN QUERY
  -- Parents
  SELECT 'father'::text, b.id, b.name, b.gender, false::boolean
  FROM public.birds b
  WHERE b.id = (SELECT father_id FROM public.birds WHERE id = bird_id AND user_id = user_id)
  
  UNION ALL
  
  SELECT 'mother'::text, b.id, b.name, b.gender, false::boolean
  FROM public.birds b
  WHERE b.id = (SELECT mother_id FROM public.birds WHERE id = bird_id AND user_id = user_id)
  
  UNION ALL
  
  -- Children (birds)
  SELECT 'child'::text, b.id, b.name, b.gender, false::boolean
  FROM public.birds b
  WHERE (b.father_id = bird_id OR b.mother_id = bird_id) AND b.user_id = user_id
  
  UNION ALL
  
  -- Children (chicks)
  SELECT 'child'::text, c.id, c.name, c.gender, true::boolean
  FROM public.chicks c
  WHERE (c.father_id = bird_id OR c.mother_id = bird_id) AND c.user_id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- Statistics function
CREATE OR REPLACE FUNCTION public.get_user_statistics(user_id uuid)
RETURNS TABLE(
  total_birds bigint,
  total_chicks bigint,
  total_eggs bigint,
  active_incubations bigint,
  total_photos bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*) FROM public.birds WHERE user_id = get_user_statistics.user_id),
    (SELECT COUNT(*) FROM public.chicks WHERE user_id = get_user_statistics.user_id),
    (SELECT COUNT(*) FROM public.eggs WHERE user_id = get_user_statistics.user_id),
    (SELECT COUNT(*) FROM public.incubations WHERE user_id = get_user_statistics.user_id AND start_date >= CURRENT_DATE - INTERVAL '30 days'),
    (SELECT COUNT(*) FROM public.photos WHERE user_id = get_user_statistics.user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- 22. CIRCULAR REFERENCE FIX
-- Eggs tablosundaki chick_id foreign key'ini ekle
ALTER TABLE public.eggs 
ADD CONSTRAINT fk_eggs_chick_id 
FOREIGN KEY (chick_id) REFERENCES public.chicks(id) ON DELETE SET NULL;

-- Migration tamamlandı
SELECT 'Database schema created successfully with RLS policies' as status; 