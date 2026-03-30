
-- "select own deleted" politikasi: sadece is_deleted sutunu olan tablolar

CREATE POLICY "birds: select own deleted"
ON public.birds FOR SELECT TO authenticated
USING ((select auth.uid()) = user_id AND is_deleted = TRUE);

CREATE POLICY "breeding_pairs: select own deleted"
ON public.breeding_pairs FOR SELECT TO authenticated
USING ((select auth.uid()) = user_id AND is_deleted = TRUE);

CREATE POLICY "clutches: select own deleted"
ON public.clutches FOR SELECT TO authenticated
USING ((select auth.uid()) = user_id AND is_deleted = TRUE);

CREATE POLICY "eggs: select own deleted"
ON public.eggs FOR SELECT TO authenticated
USING ((select auth.uid()) = user_id AND is_deleted = TRUE);

CREATE POLICY "chicks: select own deleted"
ON public.chicks FOR SELECT TO authenticated
USING ((select auth.uid()) = user_id AND is_deleted = TRUE);

CREATE POLICY "health_records: select own deleted"
ON public.health_records FOR SELECT TO authenticated
USING ((select auth.uid()) = user_id AND is_deleted = TRUE);

CREATE POLICY "calendar: select own deleted"
ON public.calendar FOR SELECT TO authenticated
USING ((select auth.uid()) = user_id AND is_deleted = TRUE);
;
