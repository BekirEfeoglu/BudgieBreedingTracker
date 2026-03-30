
-- audit_logs: admin denetim kayitlari
-- Hicbir zaman silinmez/guncellenmez, is_deleted yok
CREATE TABLE public.audit_logs (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  action     TEXT        NOT NULL,
  table_name TEXT,
  record_id  UUID,
  old_data   JSONB,
  new_data   JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_id    ON public.audit_logs(user_id);
CREATE INDEX idx_audit_logs_action     ON public.audit_logs(action);
CREATE INDEX idx_audit_logs_table_name ON public.audit_logs(table_name);
CREATE INDEX idx_audit_logs_created_at ON public.audit_logs(created_at);

-- RLS
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Sadece admin okuyabilir/yazabilir
CREATE POLICY "audit_logs: admin all"
ON public.audit_logs FOR ALL
TO authenticated
USING ( (select public.is_admin()) );

-- Kullanicilar kendi aksiyonlarini loglayabilir (sadece INSERT)
CREATE POLICY "audit_logs: insert own"
ON public.audit_logs FOR INSERT
TO authenticated
WITH CHECK ( (select auth.uid()) = user_id );

-- GRANT: sadece authenticated INSERT (admin service key ile full bypass)
REVOKE ALL ON public.audit_logs FROM anon;
GRANT INSERT ON public.audit_logs TO authenticated;
;
