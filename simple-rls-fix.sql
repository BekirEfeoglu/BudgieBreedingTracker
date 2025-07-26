<<<<<<< HEAD
-- BASİT RLS DÜZELTME
-- Bu dosyayı Supabase SQL Editor'de çalıştırın

-- 1. Mevcut kullanıcıyı bul ve ID'sini al
DO $$
DECLARE
  current_user_id UUID;
BEGIN
  -- En son oluşturulan kullanıcıyı al
  SELECT id INTO current_user_id 
  FROM auth.users 
  ORDER BY created_at DESC 
  LIMIT 1;
  
  RAISE NOTICE 'Kullanıcı ID: %', current_user_id;
  
  -- Mevcut verileri bu kullanıcıya ata
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

-- 2. Tüm RLS politikalarını temizle
=======
-- BASİT RLS DÜZELTMESİ
-- Bu SQL kodunu Supabase SQL Editor'de çalıştırın

-- 1. Tüm mevcut politikaları temizle
>>>>>>> 045fcb9ce5bff88b6d112f3a0e741160523df7a7
DROP POLICY IF EXISTS "Users can view their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can create their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can manage their own birds" ON public.birds;

DROP POLICY IF EXISTS "Users can view their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can create their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can update their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can delete their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can manage their own chicks" ON public.chicks;

DROP POLICY IF EXISTS "Users can view their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can create their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can update their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can delete their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can manage their own eggs" ON public.eggs;

DROP POLICY IF EXISTS "Users can view their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can create their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can update their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can delete their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can manage their own incubations" ON public.incubations;

DROP POLICY IF EXISTS "Users can manage their own notification settings" ON public.user_notification_settings;
<<<<<<< HEAD

-- 3. RLS'yi etkinleştir
=======
DROP POLICY IF EXISTS "Users can manage their own notification tokens" ON public.user_notification_tokens;
DROP POLICY IF EXISTS "Users can manage their own notification interactions" ON public.notification_interactions;

-- 2. Yeni basit politikalar oluştur
CREATE POLICY "Users can manage their own birds" ON public.birds FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own chicks" ON public.chicks FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own eggs" ON public.eggs FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own incubations" ON public.incubations FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own notification settings" ON public.user_notification_settings FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own notification tokens" ON public.user_notification_tokens FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own notification interactions" ON public.notification_interactions FOR ALL USING (auth.uid() = user_id);

-- 3. RLS'yi aktif et
>>>>>>> 045fcb9ce5bff88b6d112f3a0e741160523df7a7
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;
<<<<<<< HEAD

-- 4. Basit politikalar oluştur (auth.uid() yerine sabit kullanıcı ID)
CREATE POLICY "Enable all access for authenticated users" 
ON public.birds 
FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable all access for authenticated users" 
ON public.chicks 
FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable all access for authenticated users" 
ON public.eggs 
FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable all access for authenticated users" 
ON public.incubations 
FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable all access for authenticated users" 
ON public.user_notification_settings 
FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- 5. Test verisi ekle
INSERT INTO public.birds (user_id, name, gender, color, birth_date, ring_number)
VALUES (
  (SELECT id FROM auth.users ORDER BY created_at DESC LIMIT 1), 
  'SIMPLE_RLS_TEST_BIRD', 
  'male', 
  'Test', 
  '2023-01-01', 
  'SIMPLE-001'
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
  cmd
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings')
ORDER BY tablename, cmd; 
=======
ALTER TABLE public.user_notification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_interactions ENABLE ROW LEVEL SECURITY;

-- 4. Bildirim ayarlarını mevcut kullanıcılar için oluştur
INSERT INTO public.user_notification_settings (user_id)
SELECT id FROM auth.users
ON CONFLICT (user_id) DO NOTHING; 
>>>>>>> 045fcb9ce5bff88b6d112f3a0e741160523df7a7
