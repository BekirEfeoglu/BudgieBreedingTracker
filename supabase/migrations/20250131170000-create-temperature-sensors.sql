-- Sıcaklık sensörleri için tablolar

-- Sıcaklık sensörleri tablosu
CREATE TABLE IF NOT EXISTS public.temperature_sensors (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('bluetooth', 'wifi', 'usb')),
  target_temp DECIMAL(4,2) NOT NULL DEFAULT 37.5,
  target_humidity INTEGER DEFAULT 60,
  temp_tolerance DECIMAL(3,1) NOT NULL DEFAULT 0.5,
  humidity_tolerance INTEGER DEFAULT 5,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sıcaklık okumaları tablosu
CREATE TABLE IF NOT EXISTS public.temperature_readings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sensor_id UUID NOT NULL REFERENCES public.temperature_sensors(id) ON DELETE CASCADE,
  temperature DECIMAL(4,2) NOT NULL,
  humidity INTEGER,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_temperature_sensors_user_id ON public.temperature_sensors(user_id);
CREATE INDEX IF NOT EXISTS idx_temperature_readings_user_id ON public.temperature_readings(user_id);
CREATE INDEX IF NOT EXISTS idx_temperature_readings_sensor_id ON public.temperature_readings(sensor_id);
CREATE INDEX IF NOT EXISTS idx_temperature_readings_timestamp ON public.temperature_readings(timestamp);

-- RLS politikaları
ALTER TABLE public.temperature_sensors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.temperature_readings ENABLE ROW LEVEL SECURITY;

-- Temperature sensors RLS policies
CREATE POLICY "Users can view their own temperature sensors" ON public.temperature_sensors
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own temperature sensors" ON public.temperature_sensors
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own temperature sensors" ON public.temperature_sensors
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own temperature sensors" ON public.temperature_sensors
  FOR DELETE USING (auth.uid() = user_id);

-- Temperature readings RLS policies
CREATE POLICY "Users can view their own temperature readings" ON public.temperature_readings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own temperature readings" ON public.temperature_readings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own temperature readings" ON public.temperature_readings
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own temperature readings" ON public.temperature_readings
  FOR DELETE USING (auth.uid() = user_id); 