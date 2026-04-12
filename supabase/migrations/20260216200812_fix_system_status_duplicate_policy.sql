
-- system_status için tekrarlayan permissive SELECT politikasını düzelt
-- Mevcut system_status_all ALL policy'yi kaldırıp ayrı ayrı oluştur
-- Böylece SELECT için tek bir birleşik policy olur

DROP POLICY IF EXISTS "system_status_all" ON public.system_status;
DROP POLICY IF EXISTS "Users can view system status" ON public.system_status;

-- Herkes status görebilsin (authenticated)
CREATE POLICY "Users can view system status" ON public.system_status
  FOR SELECT TO authenticated
  USING (true);

-- Yalnızca admin'ler INSERT/UPDATE/DELETE yapabilsin
CREATE POLICY "Admins can insert system status" ON public.system_status
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users));

CREATE POLICY "Admins can update system status" ON public.system_status
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users))
  WITH CHECK ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users));

CREATE POLICY "Admins can delete system status" ON public.system_status
  FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) IN (SELECT user_id FROM admin_users));
;
