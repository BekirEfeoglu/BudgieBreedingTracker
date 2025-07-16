-- Incubations tablosundaki çakışan policy'leri temizle
-- Önce mevcut policy'leri listele
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'incubations'
ORDER BY policyname;

-- Eski policy'leri sil
DROP POLICY IF EXISTS "Users can create their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can view their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can update their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can delete their own incubations" ON public.incubations;

-- Ana policy'yi güncelle (performans için optimize et)
DROP POLICY IF EXISTS "Users can manage their own incubations" ON public.incubations;
CREATE POLICY "Users can manage their own incubations" ON public.incubations 
FOR ALL USING ((select auth.uid()) = user_id);

-- Policy'lerin temizlendiğini kontrol et
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename = 'incubations'
ORDER BY policyname; 