-- RLS FİNAL DÜZELTME
-- Bu dosyayı Supabase SQL Editor'de çalıştırın

-- 1. Mevcut kullanıcıyı bul
DO $$
DECLARE
  current_user_id UUID;
BEGIN
  SELECT id INTO current_user_id 
  FROM auth.users 
  ORDER BY created_at DESC 
  LIMIT 1;
  
  RAISE NOTICE 'Kullanıcı ID: %', current_user_id;
  
  -- Mevcut verileri düzelt
  UPDATE public.birds SET user_id = current_user_id WHERE user_id IS NULL;
  UPDATE public.chicks SET user_id = current_user_id WHERE user_id IS NULL;
  UPDATE public.eggs SET user_id = current_user_id WHERE user_id IS NULL;
  UPDATE public.incubations SET user_id = current_user_id WHERE user_id IS NULL;
  
  -- Bildirim ayarlarını oluştur
  INSERT INTO public.user_notification_settings (user_id)
  VALUES (current_user_id)
  ON CONFLICT (user_id) DO NOTHING;
  
  RAISE NOTICE 'Veriler güncellendi';
END $$;

-- 2. Tüm politikaları temizle
DROP POLICY IF EXISTS "Users can view their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can create their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can manage their own birds" ON public.birds;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.birds;

DROP POLICY IF EXISTS "Users can view their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can create their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can update their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can delete their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can manage their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.chicks;

DROP POLICY IF EXISTS "Users can view their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can create their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can update their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can delete their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can manage their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.eggs;

DROP POLICY IF EXISTS "Users can view their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can create their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can update their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can delete their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can manage their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.incubations;

DROP POLICY IF EXISTS "Users can manage their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.user_notification_settings;

-- 3. RLS'yi etkinleştir
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

-- 4. Yeni politikalar oluştur (auth.uid() ile)
CREATE POLICY "Users can view their own birds" 
ON public.birds 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own birds" 
ON public.birds 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own birds" 
ON public.birds 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own birds" 
ON public.birds 
FOR DELETE 
USING (auth.uid() = user_id);

-- Chicks için
CREATE POLICY "Users can view their own chicks" 
ON public.chicks 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own chicks" 
ON public.chicks 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own chicks" 
ON public.chicks 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own chicks" 
ON public.chicks 
FOR DELETE 
USING (auth.uid() = user_id);

-- Eggs için
CREATE POLICY "Users can view their own eggs" 
ON public.eggs 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own eggs" 
ON public.eggs 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own eggs" 
ON public.eggs 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own eggs" 
ON public.eggs 
FOR DELETE 
USING (auth.uid() = user_id);

-- Incubations için
CREATE POLICY "Users can view their own incubations" 
ON public.incubations 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own incubations" 
ON public.incubations 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own incubations" 
ON public.incubations 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own incubations" 
ON public.incubations 
FOR DELETE 
USING (auth.uid() = user_id);

-- Notification settings için
CREATE POLICY "Users can view their own notification settings" 
ON public.user_notification_settings 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notification settings" 
ON public.user_notification_settings 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notification settings" 
ON public.user_notification_settings 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notification settings" 
ON public.user_notification_settings 
FOR DELETE 
USING (auth.uid() = user_id);

-- 5. Test verisi ekle
INSERT INTO public.birds (user_id, name, gender, color, birth_date, ring_number)
VALUES (
  (SELECT id FROM auth.users ORDER BY created_at DESC LIMIT 1), 
  'FINAL_RLS_TEST_BIRD', 
  'male', 
  'Test', 
  '2023-01-01', 
  'FINAL-001'
) ON CONFLICT DO NOTHING;

-- 6. Son durumu kontrol et
SELECT 
  'RLS Durumu' as kontrol,
  schemaname,
  tablename,
  CASE 
    WHEN rowsecurity THEN '✅ ETKİN'
    ELSE '❌ DEVRE DIŞI'
  END as rls_durumu
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings')
ORDER BY tablename;

-- 7. Oluşturulan politikaları kontrol et
SELECT 
  'Politikalar' as kontrol,
  tablename, 
  policyname, 
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings')
ORDER BY tablename, cmd;

-- 8. Test sorgusu
SELECT 
  'Test Sorgusu' as kontrol,
  COUNT(*) as toplam_kus,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as user_id_olan
FROM public.birds; 