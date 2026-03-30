
-- events: select own deleted (sync icin)
CREATE POLICY "events: select own deleted"
ON public.events FOR SELECT
TO authenticated
USING (
  (select auth.uid()) = user_id
  AND is_deleted = TRUE
);

-- nests: select own deleted (sync icin)
CREATE POLICY "nests: select own deleted"
ON public.nests FOR SELECT
TO authenticated
USING (
  (select auth.uid()) = user_id
  AND is_deleted = TRUE
);

-- event_reminders: select own deleted (sync icin)
CREATE POLICY "event_reminders: select own deleted"
ON public.event_reminders FOR SELECT
TO authenticated
USING (
  (select auth.uid()) = user_id
  AND is_deleted = TRUE
);

-- photos: select own deleted (sync icin)
CREATE POLICY "photos: select own deleted"
ON public.photos FOR SELECT
TO authenticated
USING (
  (select auth.uid()) = user_id
  AND is_deleted = TRUE
);
;
