-- RLS Politikalarını Düzeltme
-- Bu dosya Supabase'de RLS sorunlarını çözer

-- Önce mevcut politikaları temizle
DROP POLICY IF EXISTS "Users can manage their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can manage their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can manage their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can manage their own eggs" ON public.eggs;

-- RLS'yi geçici olarak devre dışı bırak
ALTER TABLE public.birds DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs DISABLE ROW LEVEL SECURITY;

-- RLS'yi tekrar etkinleştir
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;

-- Yeni politikalar oluştur (daha esnek)
CREATE POLICY "Users can view their own birds" 
  ON public.birds FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own birds" 
  ON public.birds FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own birds" 
  ON public.birds FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own birds" 
  ON public.birds FOR DELETE 
  USING (auth.uid() = user_id);

-- Incubations için
CREATE POLICY "Users can view their own incubations" 
  ON public.incubations FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own incubations" 
  ON public.incubations FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own incubations" 
  ON public.incubations FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own incubations" 
  ON public.incubations FOR DELETE 
  USING (auth.uid() = user_id);

-- Chicks için
CREATE POLICY "Users can view their own chicks" 
  ON public.chicks FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own chicks" 
  ON public.chicks FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own chicks" 
  ON public.chicks FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own chicks" 
  ON public.chicks FOR DELETE 
  USING (auth.uid() = user_id);

-- Eggs için
CREATE POLICY "Users can view their own eggs" 
  ON public.eggs FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own eggs" 
  ON public.eggs FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own eggs" 
  ON public.eggs FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own eggs" 
  ON public.eggs FOR DELETE 
  USING (auth.uid() = user_id);

-- Auth fonksiyonlarını kontrol et
SELECT 
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
  AND tablename IN ('birds', 'incubations', 'chicks', 'eggs');

-- Test için geçici olarak RLS'yi devre dışı bırak (sadece test için)
-- ALTER TABLE public.birds DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.incubations DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.chicks DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.eggs DISABLE ROW LEVEL SECURITY; 