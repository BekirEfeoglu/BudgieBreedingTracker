
-- "admin all" politikasi: tum core tablolar

CREATE POLICY "birds: admin all"
ON public.birds FOR ALL TO authenticated
USING ((select public.is_admin()));

CREATE POLICY "breeding_pairs: admin all"
ON public.breeding_pairs FOR ALL TO authenticated
USING ((select public.is_admin()));

CREATE POLICY "clutches: admin all"
ON public.clutches FOR ALL TO authenticated
USING ((select public.is_admin()));

CREATE POLICY "eggs: admin all"
ON public.eggs FOR ALL TO authenticated
USING ((select public.is_admin()));

CREATE POLICY "chicks: admin all"
ON public.chicks FOR ALL TO authenticated
USING ((select public.is_admin()));

CREATE POLICY "health_records: admin all"
ON public.health_records FOR ALL TO authenticated
USING ((select public.is_admin()));

CREATE POLICY "growth_measurements: admin all"
ON public.growth_measurements FOR ALL TO authenticated
USING ((select public.is_admin()));

CREATE POLICY "incubations: admin all"
ON public.incubations FOR ALL TO authenticated
USING ((select public.is_admin()));

CREATE POLICY "notifications: admin all"
ON public.notifications FOR ALL TO authenticated
USING ((select public.is_admin()));

CREATE POLICY "calendar: admin all"
ON public.calendar FOR ALL TO authenticated
USING ((select public.is_admin()));

CREATE POLICY "feedback: admin all"
ON public.feedback FOR ALL TO authenticated
USING ((select public.is_admin()));

CREATE POLICY "profiles: admin all"
ON public.profiles FOR ALL TO authenticated
USING ((select public.is_admin()));
;
