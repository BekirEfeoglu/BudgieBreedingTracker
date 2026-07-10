-- =============================================================================
-- Marketplace listing server-side text moderation (BEFORE INSERT)
-- =============================================================================
-- Marketplace listing text moderation was CLIENT-SIDE ONLY: the client runs
-- checkText before a direct `.upsert()` to marketplace_listings, but the RLS
-- INSERT policy only checked ownership (user_id = auth.uid()) and there was no
-- insert-time moderation. A tampered client or direct REST call could insert a
-- scam/illegal listing skipping moderation; it defaults needs_review=false +
-- status=active and is immediately public.
--
-- This enforces the SAME moderation the community edge functions apply
-- (supabase/functions/moderate-content/moderation.ts -> moderateText) at the
-- DB level, so it cannot be bypassed by any client (old, new, or tampered) and
-- does NOT break legitimate inserts (they pass moderation exactly as community
-- posts do). Reversible: DROP TRIGGER if it ever misfires.
--
-- Scope is BEFORE INSERT only: edits are already covered by the existing
-- needs_review-on-edit flag trigger (20260501120000), which hides an edited
-- listing pending review.
--
-- NOTE: private.marketplace_moderation_violation mirrors PROHIBITED_PATTERNS +
-- the caps/repeat/URL heuristics in moderate-content/moderation.ts. Keep the
-- two in sync when either changes (the client Dart filter + the TS edge fn +
-- this SQL mirror are the three copies of this denylist by design).
-- =============================================================================

-- Pure moderation predicate: returns a violation reason, or NULL if clean.
-- Lives in the private schema so it is NOT exposed via PostgREST.
CREATE OR REPLACE FUNCTION private.marketplace_moderation_violation(p_text text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  v_normalized text := lower(coalesce(p_text, ''));
  v_len        integer := length(coalesce(p_text, ''));
  v_pattern    text;
  v_upper      integer;
  v_url_count  integer;
  v_prohibited text[] := ARRAY[
    -- Violence & threats (EN/TR/DE)
    'i will kill', 'death threat', 'bomb threat',
    'seni öldürür', 'bomba atacağ',
    'ich werde dich töten', 'bombendrohung',
    -- Spam / scam
    'buy followers', 'free money', 'click here to win',
    'takipçi satın', 'bedava para', 'hemen tıkla kazan',
    'follower kaufen', 'gratis geld',
    -- URL spam
    'bit.ly/', 'tinyurl.com/',
    -- Self-harm
    'how to kill yourself', 'intihar yöntemi', 'suizidmethode'
  ];
BEGIN
  IF v_len = 0 THEN
    RETURN NULL;
  END IF;

  FOREACH v_pattern IN ARRAY v_prohibited LOOP
    IF position(v_pattern IN v_normalized) > 0 THEN
      RETURN 'content_violation';
    END IF;
  END LOOP;

  -- Excessive caps (>70% uppercase letters) for text longer than 20 chars.
  IF v_len > 20 THEN
    v_upper := v_len - length(regexp_replace(p_text, '[[:upper:]]', '', 'g'));
    IF v_upper::numeric / v_len > 0.7 THEN
      RETURN 'excessive_caps';
    END IF;
  END IF;

  -- Repeated-character spam: same char 10+ times in a row.
  IF v_normalized ~ '(.)\1{9,}' THEN
    RETURN 'spam_detected';
  END IF;

  -- URL flood: more than 3 links.
  v_url_count := (
    SELECT count(*) FROM regexp_matches(v_normalized, 'https?://', 'g')
  );
  IF v_url_count > 3 THEN
    RETURN 'spam_detected';
  END IF;

  RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION private.marketplace_moderation_violation(text)
  FROM PUBLIC, anon, authenticated;

-- Trigger: reject an insert whose moderatable text fails moderation. The
-- message carries a stable MARKETPLACE_MODERATION_REJECTED marker + reason the
-- client maps to a localized moderation error.
CREATE OR REPLACE FUNCTION private.enforce_marketplace_listing_moderation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_reason text;
BEGIN
  v_reason := private.marketplace_moderation_violation(
    concat_ws(' ', NEW.title, NEW.description, NEW.species, NEW.mutation)
  );

  IF v_reason IS NOT NULL THEN
    RAISE EXCEPTION 'MARKETPLACE_MODERATION_REJECTED: %', v_reason
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.enforce_marketplace_listing_moderation()
  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_moderate_marketplace_listing
  ON public.marketplace_listings;
CREATE TRIGGER trg_moderate_marketplace_listing
  BEFORE INSERT ON public.marketplace_listings
  FOR EACH ROW
  EXECUTE FUNCTION private.enforce_marketplace_listing_moderation();

COMMENT ON FUNCTION private.marketplace_moderation_violation(text) IS
  'Pure text-moderation predicate for marketplace listings; mirrors '
  'moderate-content/moderation.ts moderateText. Returns a violation reason or '
  'NULL. Trigger-only (no client EXECUTE).';
COMMENT ON FUNCTION private.enforce_marketplace_listing_moderation() IS
  'BEFORE INSERT moderation guard for marketplace_listings — server-side '
  'enforcement no client can skip. Trigger-only (no client EXECUTE).';
