-- Record and aggregate app build adoption from user_sessions.
--
-- The app writes app_version as "<semantic-version>+<build-number>" when a
-- foreground session starts. Existing rows remain nullable so older clients
-- continue to work during the rollout overlap window.

COMMENT ON COLUMN public.user_sessions.app_version IS
  'Installed app version in <semantic-version>+<build-number> form; nullable for legacy clients.';

CREATE INDEX IF NOT EXISTS idx_user_sessions_build_distribution
  ON public.user_sessions (platform, last_active_at DESC, user_id, app_version)
  WHERE platform IN ('ios', 'android');

CREATE OR REPLACE FUNCTION private.admin_get_build_distribution(
  p_days integer DEFAULT 30
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM private.require_active_admin();

  IF p_days IS NULL OR p_days < 1 OR p_days > 90 THEN
    RAISE EXCEPTION 'admin.invalid_build_distribution_window';
  END IF;

  RETURN (
    WITH ranked_sessions AS (
      SELECT
        s.platform,
        s.user_id,
        NULLIF(BTRIM(s.app_version), '') AS app_version,
        COALESCE(s.last_active_at, s.created_at) AS observed_at,
        ROW_NUMBER() OVER (
          PARTITION BY s.user_id, s.platform
          ORDER BY
            COALESCE(s.last_active_at, s.created_at) DESC,
            s.created_at DESC,
            s.id DESC
        ) AS recency_rank
      FROM public.user_sessions s
      WHERE COALESCE(s.last_active_at, s.created_at) >=
        now() - make_interval(days => p_days)
        AND s.platform IN ('ios', 'android')
    ),
    latest_sessions AS (
      SELECT platform, user_id, app_version, observed_at
      FROM ranked_sessions
      WHERE recency_rank = 1
    ),
    platform_totals AS (
      SELECT
        platform,
        COUNT(*)::integer AS total_users,
        COUNT(app_version)::integer AS versioned_users
      FROM latest_sessions
      GROUP BY platform
    ),
    build_counts AS (
      SELECT
        platform,
        app_version,
        COUNT(*)::integer AS user_count,
        MAX(observed_at) AS last_seen_at
      FROM latest_sessions
      WHERE app_version IS NOT NULL
      GROUP BY platform, app_version
    )
    SELECT jsonb_build_object(
      'window_days', p_days,
      'generated_at', now(),
      'platforms',
      COALESCE(
        jsonb_agg(
          jsonb_build_object(
            'platform', totals.platform,
            'total_users', totals.total_users,
            'versioned_users', totals.versioned_users,
            'coverage_percent',
              CASE
                WHEN totals.total_users = 0 THEN 0
                ELSE ROUND(
                  totals.versioned_users::numeric * 100 / totals.total_users,
                  1
                )
              END,
            'builds',
              COALESCE(
                (
                  SELECT jsonb_agg(
                    jsonb_build_object(
                      'app_version', counts.app_version,
                      'user_count', counts.user_count,
                      'adoption_percent',
                        CASE
                          WHEN totals.total_users = 0 THEN 0
                          ELSE ROUND(
                            counts.user_count::numeric * 100 / totals.total_users,
                            1
                          )
                        END,
                      'last_seen_at', counts.last_seen_at
                    )
                    ORDER BY counts.user_count DESC, counts.app_version DESC
                  )
                  FROM build_counts counts
                  WHERE counts.platform = totals.platform
                ),
                '[]'::jsonb
              )
          )
          ORDER BY totals.platform
        ),
        '[]'::jsonb
      )
    )
    FROM platform_totals totals
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_get_build_distribution(
  p_days integer DEFAULT 30
)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_get_build_distribution(p_days);
$$;

REVOKE ALL ON FUNCTION private.admin_get_build_distribution(integer)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_get_build_distribution(integer)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.admin_get_build_distribution(integer)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_get_build_distribution(integer)
  TO authenticated, service_role;

COMMENT ON FUNCTION public.admin_get_build_distribution(integer) IS
  'Admin-only build adoption rollup using each user-platform latest session in the requested window.';
