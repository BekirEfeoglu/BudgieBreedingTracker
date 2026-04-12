
-- anon role'den gereksiz izinleri kaldir
REVOKE ALL ON public.events FROM anon;
REVOKE ALL ON public.event_reminders FROM anon;
REVOKE ALL ON public.nests FROM anon;
REVOKE ALL ON public.notification_schedules FROM anon;
REVOKE ALL ON public.photos FROM anon;

-- authenticated'a sadece CRUD ver (RLS satir kontrolunu ustlenir)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.events TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.event_reminders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.nests TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notification_schedules TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.photos TO authenticated;

-- audit_logs: authenticated sadece INSERT yapabilmeli
REVOKE ALL ON public.audit_logs FROM authenticated;
GRANT INSERT ON public.audit_logs TO authenticated;
-- Admin service key uzerinden tum erisimi zaten bypass eder
;
