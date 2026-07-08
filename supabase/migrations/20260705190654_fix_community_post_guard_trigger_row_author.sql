-- Fix: create-community-post always failed with 400 (insert_failed) and the
-- client surfaced a generic "Beklenmeyen bir hata oluştu." — no post could ever
-- be created.
--
-- Root cause: the BEFORE INSERT guard trigger
-- internal.enforce_community_post_guards() evaluated the guard via
-- public.check_community_post_allowed(), which reads auth.uid(). The only
-- legitimate insert path is the create-community-post edge function, which
-- writes as service_role — there auth.uid() is NULL, so the guard returned
-- {allowed:false, reason:'unauthorized'} and the trigger RAISEd on EVERY insert.
--
-- Fix: evaluate the guard against the row's author (NEW.user_id) using the
-- explicit-user private helper. This restores post creation while keeping the
-- DB-level defense-in-depth (account age, hourly/daily rate limit, duplicate
-- content) enforced against the actual posting user regardless of session
-- context. The edge function already runs the same check with the user's JWT
-- (returns 429 on denial) before the insert; this trigger remains the
-- authoritative DB-level backstop.
--
-- The previous public.is_admin() short-circuit is dropped: it read auth.uid()
-- (NULL on the service_role path, so it never fired) and the edge function's
-- own pre-insert guard applies no admin bypass either, so behavior is unchanged.

CREATE OR REPLACE FUNCTION internal.enforce_community_post_guards()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_result jsonb;
  v_reason text;
BEGIN
  v_result := private.check_community_post_allowed_for_user(
    NEW.user_id,
    NEW.content_hash
  );

  IF (v_result->>'allowed')::boolean IS DISTINCT FROM true THEN
    v_reason := coalesce(v_result->>'reason', 'denied');
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'community_post_guard_denied',
      DETAIL  = v_reason,
      HINT    = 'Matches client-side check_community_post_allowed reason codes';
  END IF;

  RETURN NEW;
END;
$function$;
