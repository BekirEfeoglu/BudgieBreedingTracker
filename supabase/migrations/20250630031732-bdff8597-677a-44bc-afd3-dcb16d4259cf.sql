
-- Performans uyarılarını düzeltmek için RLS politikalarını güncelle
-- Mevcut politikaları kaldır
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;

-- Optimize edilmiş RLS politikaları oluştur
-- auth.uid() çağrılarını (SELECT auth.uid()) ile sararak performansı artır
CREATE POLICY "Users can view their own profile" 
  ON public.profiles 
  FOR SELECT 
  USING ((SELECT auth.uid()) = id);

CREATE POLICY "Users can update their own profile" 
  ON public.profiles 
  FOR UPDATE 
  USING ((SELECT auth.uid()) = id);

CREATE POLICY "Users can insert their own profile" 
  ON public.profiles 
  FOR INSERT 
  WITH CHECK ((SELECT auth.uid()) = id);
