
-- Dokumana gore: tum tablolardan anon yetkisini kaldir
-- RLS + authenticated policy'ler yeterli
DO $$
DECLARE
  tbl TEXT;
  tables TEXT[] := ARRAY[
    'profiles','birds','breeding_pairs','clutches','eggs','chicks',
    'health_records','growth_measurements','genetics_history',
    'calendar','notifications','sync_metadata',
    'feedback','incubations'
  ];
BEGIN
  FOREACH tbl IN ARRAY tables LOOP
    EXECUTE format('REVOKE ALL ON public.%I FROM anon', tbl);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', tbl);
  END LOOP;
END;
$$;
;
