-- Bildirim sistemi için gerekli tablolar

-- FCM token yönetimi
CREATE TABLE IF NOT EXISTS public.user_notification_tokens (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  device_info JSONB,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Kullanıcı bildirim ayarları
CREATE TABLE IF NOT EXISTS public.user_notification_settings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  egg_turning_enabled BOOLEAN DEFAULT TRUE,
  egg_turning_interval INTEGER DEFAULT 240,
  temperature_alerts_enabled BOOLEAN DEFAULT TRUE,
  temperature_min DECIMAL(4,2) DEFAULT 37.5,
  temperature_max DECIMAL(4,2) DEFAULT 37.8,
  temperature_tolerance DECIMAL(3,1) DEFAULT 0.5,
  humidity_alerts_enabled BOOLEAN DEFAULT TRUE,
  humidity_min INTEGER DEFAULT 55,
  humidity_max INTEGER DEFAULT 65,
  feeding_reminders_enabled BOOLEAN DEFAULT TRUE,
  feeding_interval INTEGER DEFAULT 8,
  do_not_disturb_start TIME,
  do_not_disturb_end TIME,
  language TEXT DEFAULT 'tr' CHECK (language IN ('tr', 'en')),
  sound_enabled BOOLEAN DEFAULT TRUE,
  vibration_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Bildirim etkileşim geçmişi
CREATE TABLE IF NOT EXISTS public.notification_interactions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_id TEXT NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('received', 'clicked', 'dismissed', 'snoozed')),
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB
);

-- RLS politikaları
ALTER TABLE public.user_notification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_interactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own notification tokens" ON public.user_notification_tokens 
FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own notification settings" ON public.user_notification_settings 
FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own notification interactions" ON public.notification_interactions 
FOR ALL USING (auth.uid() = user_id);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_notification_tokens_user_id ON public.user_notification_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_settings_user_id ON public.user_notification_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_interactions_user_id ON public.notification_interactions(user_id);

-- Mevcut kullanıcılar için bildirim ayarlarını oluştur
INSERT INTO public.user_notification_settings (user_id)
SELECT id FROM auth.users
ON CONFLICT (user_id) DO NOTHING; 