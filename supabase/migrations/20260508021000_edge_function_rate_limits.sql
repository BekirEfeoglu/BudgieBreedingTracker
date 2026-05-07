-- Durable rate-limit store for Supabase Edge Functions.

CREATE SCHEMA IF NOT EXISTS private;
GRANT USAGE ON SCHEMA private TO service_role;

CREATE TABLE IF NOT EXISTS private.edge_rate_limits (
  key text NOT NULL,
  bucket_start timestamptz NOT NULL,
  request_count integer NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (key, bucket_start)
);

ALTER TABLE private.edge_rate_limits ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.edge_rate_limits FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON private.edge_rate_limits TO service_role;

CREATE INDEX IF NOT EXISTS idx_edge_rate_limits_updated_at
ON private.edge_rate_limits (updated_at);

CREATE OR REPLACE FUNCTION public.check_edge_rate_limit(
  p_key text,
  p_window_ms integer,
  p_max_calls integer
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public
AS $$
DECLARE
  v_bucket_seconds numeric;
  v_bucket_start timestamptz;
  v_request_count integer;
BEGIN
  IF p_key IS NULL
    OR length(p_key) = 0
    OR length(p_key) > 512
    OR p_window_ms < 1000
    OR p_max_calls < 1 THEN
    RETURN false;
  END IF;

  v_bucket_seconds := p_window_ms::numeric / 1000;
  v_bucket_start := to_timestamp(
    floor(extract(epoch FROM statement_timestamp()) / v_bucket_seconds)
    * v_bucket_seconds
  );

  DELETE FROM private.edge_rate_limits
  WHERE bucket_start < statement_timestamp() - interval '1 day';

  INSERT INTO private.edge_rate_limits AS erl (
    key,
    bucket_start,
    request_count,
    updated_at
  )
  VALUES (p_key, v_bucket_start, 1, statement_timestamp())
  ON CONFLICT (key, bucket_start) DO UPDATE
  SET
    request_count = erl.request_count + 1,
    updated_at = statement_timestamp()
  RETURNING request_count INTO v_request_count;

  RETURN v_request_count <= p_max_calls;
END;
$$;

REVOKE ALL ON FUNCTION public.check_edge_rate_limit(text, integer, integer)
FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_edge_rate_limit(text, integer, integer)
TO service_role;
