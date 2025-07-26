-- RLS POLİTİKALARINI DÜZELT - KUŞLARIN GÖRÜNMEMESİ SORUNUNU ÇÖZ
-- Bu dosyayı Supabase SQL Editor'de çalıştırın

-- 1. Önce mevcut durumu kontrol et
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings')
ORDER BY tablename;

-- 2. Tüm mevcut politikaları temizle
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

-- 3. Yeni optimize edilmiş politikalar oluştur (SELECT auth.uid() kullanarak)
CREATE POLICY "Users can manage their own birds" 
ON public.birds 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can manage their own chicks" 
ON public.chicks 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can manage their own eggs" 
ON public.eggs 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can manage their own incubations" 
ON public.incubations 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can manage their own notification settings" 
ON public.user_notification_settings 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can manage their own notification tokens" 
ON public.user_notification_tokens 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can manage their own notification interactions" 
ON public.notification_interactions 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 4. RLS'yi aktif et
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_interactions ENABLE ROW LEVEL SECURITY;

-- 5. Mevcut kuşların user_id'lerini kontrol et ve düzelt
SELECT 
  id,
  name,
  user_id,
  created_at
FROM public.birds
ORDER BY created_at DESC
LIMIT 10;

-- 6. Eğer user_id boşsa, mevcut kullanıcıya ata
UPDATE public.birds 
SET user_id = (SELECT id FROM auth.users LIMIT 1)
WHERE user_id IS NULL;

-- 7. Son durumu kontrol et
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'chicks', 'eggs', 'incubations', 'user_notification_settings')
ORDER BY tablename;

-- 8. Politikaları kontrol et
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

-- 9. Test sorgusu - kullanıcının kuşlarını kontrol et
SELECT 
  COUNT(*) as bird_count,
  (SELECT auth.uid()) as current_user_id
FROM public.birds 
WHERE user_id = (SELECT auth.uid()); 