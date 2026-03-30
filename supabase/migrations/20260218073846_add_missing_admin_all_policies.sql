
-- nests: admin all
CREATE POLICY "nests: admin all"
ON public.nests FOR ALL
TO authenticated
USING ( (select public.is_admin()) );

-- events: admin all
CREATE POLICY "events: admin all"
ON public.events FOR ALL
TO authenticated
USING ( (select public.is_admin()) );

-- event_reminders: admin all
CREATE POLICY "event_reminders: admin all"
ON public.event_reminders FOR ALL
TO authenticated
USING ( (select public.is_admin()) );

-- notification_schedules: admin all
CREATE POLICY "notification_schedules: admin all"
ON public.notification_schedules FOR ALL
TO authenticated
USING ( (select public.is_admin()) );

-- photos: admin all
CREATE POLICY "photos: admin all"
ON public.photos FOR ALL
TO authenticated
USING ( (select public.is_admin()) );
;
