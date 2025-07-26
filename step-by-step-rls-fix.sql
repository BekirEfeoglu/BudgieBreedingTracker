-- ADIM ADIM RLS DÜZELTMESİ
-- Bu dosyayı Supabase SQL Editor'de çalıştırın

-- ADIM 1: Önce RLS'yi tamamen devre dışı bırak
ALTER TABLE public.birds DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_tokens DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_interactions DISABLE ROW LEVEL SECURITY;

-- ADIM 2: Mevcut kuşları kontrol et
SELECT 
  id,
  name,
  user_id,
  created_at
FROM public.birds
ORDER BY created_at DESC
LIMIT 10;

-- ADIM 3: Mevcut kullanıcıyı bul
SELECT 
  id,
  email,
  created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- ADIM 4: Kuşların user_id'lerini mevcut kullanıcıya ata
UPDATE public.birds 
SET user_id = (SELECT id FROM auth.users ORDER BY created_at DESC LIMIT 1)
WHERE user_id IS NULL OR user_id = '00000000-0000-0000-0000-000000000000';

-- ADIM 5: Güncellenmiş kuşları kontrol et
SELECT 
  id,
  name,
  user_id,
  created_at
FROM public.birds
ORDER BY created_at DESC
LIMIT 10;

-- ADIM 6: Tüm politikaları temizle
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
DROP POLICY IF EXISTS "Users can manage their own notification tokens" ON public.user_notification_tokens;
DROP POLICY IF EXISTS "Users can manage their own notification interactions" ON public.notification_interactions;

-- ADIM 7: Basit politikalar oluştur
CREATE POLICY "Users can manage their own birds" 
ON public.birds 
FOR ALL 
USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own chicks" 
ON public.chicks 
FOR ALL 
USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own eggs" 
ON public.eggs 
FOR ALL 
USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own incubations" 
ON public.incubations 
FOR ALL 
USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own notification settings" 
ON public.user_notification_settings 
FOR ALL 
USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own notification tokens" 
ON public.user_notification_tokens 
FOR ALL 
USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own notification interactions" 
ON public.notification_interactions 
FOR ALL 
USING (auth.uid() = user_id);

-- ADIM 8: RLS'yi aktif et
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_interactions ENABLE ROW LEVEL SECURITY;

-- ADIM 9: Test sorguları
-- Kullanıcının kuşlarını kontrol et
SELECT 
  COUNT(*) as bird_count,
  auth.uid() as current_user_id
FROM public.birds 
WHERE user_id = auth.uid();

-- RLS durumunu kontrol et
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings')
ORDER BY tablename;

-- Politikaları kontrol et
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings')
ORDER BY tablename, policyname; 