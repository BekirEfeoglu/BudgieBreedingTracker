
-- Drop redundant "select own deleted" policies on 11 tables
-- (main SELECT policy already covers all user rows without is_deleted filter)
DROP POLICY "birds: select own deleted" ON public.birds;
DROP POLICY "breeding_pairs: select own deleted" ON public.breeding_pairs;
DROP POLICY "calendar: select own deleted" ON public.calendar;
DROP POLICY "chicks: select own deleted" ON public.chicks;
DROP POLICY "clutches: select own deleted" ON public.clutches;
DROP POLICY "eggs: select own deleted" ON public.eggs;
DROP POLICY "event_reminders: select own deleted" ON public.event_reminders;
DROP POLICY "events: select own deleted" ON public.events;
DROP POLICY "health_records: select own deleted" ON public.health_records;
DROP POLICY "nests: select own deleted" ON public.nests;
DROP POLICY "photos: select own deleted" ON public.photos;

-- Fix genetics_history: main SELECT policy has is_deleted=false filter (inconsistent)
-- Update to match other tables (no is_deleted filter in RLS, client handles filtering)
DROP POLICY "genetics_history: select own" ON public.genetics_history;
CREATE POLICY "genetics_history: select own" ON public.genetics_history
  FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- Now drop the redundant deleted policy for genetics_history too
DROP POLICY "genetics_history: select own deleted" ON public.genetics_history;
;
