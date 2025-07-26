-- USER_ID OTOMATİK DOLDURMA SORUNUNU ÇÖZ
-- Bu dosyayı Supabase SQL Editor'de çalıştırın

-- 1. Önce mevcut durumu kontrol et
SELECT 
  'Current user ID:' as info,
  auth.uid() as current_user_id;

-- 2. Mevcut kuşları kontrol et
SELECT 
  'Existing birds:' as info,
  COUNT(*) as total_birds,
  COUNT(CASE WHEN user_id IS NULL THEN 1 END) as birds_without_user_id
FROM public.birds;

-- 3. Kuşların detaylarını göster
SELECT 
  id,
  name,
  user_id,
  created_at
FROM public.birds
ORDER BY created_at DESC
LIMIT 10;

-- 4. user_id'si boş olan kuşları mevcut kullanıcıya ata
UPDATE public.birds 
SET user_id = auth.uid()
WHERE user_id IS NULL;

-- 5. Güncellenmiş kuşları kontrol et
SELECT 
  'Updated birds:' as info,
  COUNT(*) as total_birds,
  COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as birds_for_current_user
FROM public.birds;

-- 6. RLS politikalarını kontrol et ve düzelt
DROP POLICY IF EXISTS "Users can manage their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can manage their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can manage their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can manage their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can manage their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can manage their own notification tokens" ON public.user_notification_tokens;
DROP POLICY IF EXISTS "Users can manage their own notification interactions" ON public.notification_interactions;

-- 7. Yeni politikalar oluştur (WITH CHECK ekleyerek)
CREATE POLICY "Users can manage their own birds" 
ON public.birds 
FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own chicks" 
ON public.chicks 
FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own eggs" 
ON public.eggs 
FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own incubations" 
ON public.incubations 
FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own notification settings" 
ON public.user_notification_settings 
FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own notification tokens" 
ON public.user_notification_tokens 
FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own notification interactions" 
ON public.notification_interactions 
FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 8. RLS'yi aktif et
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_interactions ENABLE ROW LEVEL SECURITY;

-- 9. Test sorguları
-- Kullanıcının kuşlarını kontrol et
SELECT 
  'User birds count:' as info,
  COUNT(*) as bird_count,
  auth.uid() as current_user_id
FROM public.birds 
WHERE user_id = auth.uid();

-- RLS durumunu kontrol et
SELECT 
  'RLS Status:' as info,
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings')
ORDER BY tablename;

-- Politikaları kontrol et
SELECT 
  'Policies:' as info,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings')
ORDER BY tablename, policyname; 