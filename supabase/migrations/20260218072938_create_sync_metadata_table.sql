
-- sync_metadata: offline-first senkronizasyon durum takibi
CREATE TABLE public.sync_metadata (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  table_name       TEXT        NOT NULL,
  record_id        UUID        NOT NULL,
  operation        TEXT        CHECK (operation IN ('insert','update','delete')),
  status           TEXT        CHECK (status IN ('pending','synced','error','conflict')),
  retry_count      INTEGER     NOT NULL DEFAULT 0,
  last_attempted_at TIMESTAMPTZ,
  error_message    TEXT,
  payload          JSONB,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, table_name, record_id)
);

-- Indexes
CREATE INDEX idx_sync_metadata_user_id           ON public.sync_metadata(user_id);
CREATE INDEX idx_sync_metadata_status            ON public.sync_metadata(status);
CREATE INDEX idx_sync_metadata_table_name        ON public.sync_metadata(table_name);
CREATE INDEX idx_sync_metadata_last_attempted_at ON public.sync_metadata(last_attempted_at);

-- updated_at trigger
CREATE TRIGGER update_sync_metadata_updated_at
  BEFORE UPDATE ON public.sync_metadata
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- RLS
ALTER TABLE public.sync_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sync_metadata: all own"
ON public.sync_metadata FOR ALL
TO authenticated
USING ( (select auth.uid()) = user_id )
WITH CHECK ( (select auth.uid()) = user_id );

CREATE POLICY "sync_metadata: admin all"
ON public.sync_metadata FOR ALL
TO authenticated
USING ( (select public.is_admin()) );

-- GRANT
REVOKE ALL ON public.sync_metadata FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.sync_metadata TO authenticated;
;
