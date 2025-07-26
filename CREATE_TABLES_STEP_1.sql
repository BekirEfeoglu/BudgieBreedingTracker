-- BudgieBreedingTracker - Step 1: Core Tables
-- Bu dosya temel tabloları oluşturur

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

-- CIRCULAR REFERENCE FIX
-- Eggs tablosundaki chick_id foreign key'ini ekle
ALTER TABLE public.eggs 
ADD CONSTRAINT fk_eggs_chick_id 
FOREIGN KEY (chick_id) REFERENCES public.chicks(id) ON DELETE SET NULL;

SELECT 'Step 1: Core tables created successfully' as status; 