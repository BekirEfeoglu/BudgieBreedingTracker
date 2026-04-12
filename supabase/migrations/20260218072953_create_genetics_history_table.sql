
CREATE TABLE public.genetics_history (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  father_id        UUID        REFERENCES public.birds(id) ON DELETE SET NULL,
  mother_id        UUID        REFERENCES public.birds(id) ON DELETE SET NULL,
  father_mutations JSONB       NOT NULL DEFAULT '[]',
  mother_mutations JSONB       NOT NULL DEFAULT '[]',
  results          JSONB       NOT NULL DEFAULT '{}',
  notes            TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_deleted       BOOLEAN     NOT NULL DEFAULT FALSE,
  deleted_at       TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_genetics_history_user_id   ON public.genetics_history(user_id);
CREATE INDEX idx_genetics_history_father_id ON public.genetics_history(father_id);
CREATE INDEX idx_genetics_history_mother_id ON public.genetics_history(mother_id);
CREATE INDEX idx_genetics_history_results_gin ON public.genetics_history USING GIN (results);

-- updated_at trigger
CREATE TRIGGER update_genetics_history_updated_at
  BEFORE UPDATE ON public.genetics_history
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- RLS
ALTER TABLE public.genetics_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "genetics_history: select own"
ON public.genetics_history FOR SELECT
TO authenticated
USING (
  (select auth.uid()) = user_id
  AND is_deleted = FALSE
);

CREATE POLICY "genetics_history: select own deleted"
ON public.genetics_history FOR SELECT
TO authenticated
USING (
  (select auth.uid()) = user_id
  AND is_deleted = TRUE
);

CREATE POLICY "genetics_history: insert own"
ON public.genetics_history FOR INSERT
TO authenticated
WITH CHECK (
  (select auth.uid()) = user_id
);

CREATE POLICY "genetics_history: update own"
ON public.genetics_history FOR UPDATE
TO authenticated
USING  ( (select auth.uid()) = user_id )
WITH CHECK ( (select auth.uid()) = user_id );

CREATE POLICY "genetics_history: delete own"
ON public.genetics_history FOR DELETE
TO authenticated
USING ( (select auth.uid()) = user_id );

CREATE POLICY "genetics_history: admin all"
ON public.genetics_history FOR ALL
TO authenticated
USING ( (select public.is_admin()) );

-- GRANT
REVOKE ALL ON public.genetics_history FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.genetics_history TO authenticated;
;
