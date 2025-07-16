
-- Mevcut RLS politikalarını sil ve optimize edilmiş olanlarını ekle
DROP POLICY IF EXISTS "Users can view their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can create their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can update their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can delete their own incubations" ON public.incubations;

-- Optimize edilmiş RLS politikaları - auth.uid() yerine (SELECT auth.uid()) kullanarak performansı artırır
CREATE POLICY "Users can view their own incubations" 
  ON public.incubations 
  FOR SELECT 
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create their own incubations" 
  ON public.incubations 
  FOR INSERT 
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own incubations" 
  ON public.incubations 
  FOR UPDATE 
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own incubations" 
  ON public.incubations 
  FOR DELETE 
  USING ((SELECT auth.uid()) = user_id);
