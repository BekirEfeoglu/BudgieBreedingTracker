-- =============================================================================
-- Trigger functions: enforce SET search_path = '' + schema-qualified references
-- =============================================================================
-- Problem (Postgres best practices audit, Supabase linter 0011):
--   Six non-SECURITY-DEFINER trigger functions still declare no
--   `SET search_path` and reference tables without schema qualification:
--
--     1. public.sync_display_name_from_full_name()
--        — referenced `profiles` (unqualified)
--     2. public.update_marketplace_listings_updated_at()
--        — touches NEW only, but missing search_path
--     3. public.update_conversations_updated_at()
--        — touches NEW only, but missing search_path
--     4. public.update_conversation_last_message()
--        — referenced `conversations` (unqualified)
--     5. public.update_conversation_participant_count()
--        — referenced `conversations`, `conversation_participants` (unqualified)
--     6. public.sync_marketplace_listing_profile()
--        — referenced `marketplace_listings` (unqualified)
--
--   Even though these are not SECURITY DEFINER (so the immediate exploit risk
--   from a hijacked search_path is bounded by the caller's privileges), the
--   project-wide standard adopted by 20260430160000_function_search_path_consistency.sql
--   is `SET search_path = ''` with fully-qualified references everywhere. The
--   Supabase Database Linter rule 0011 (function_search_path_mutable) flags
--   these on every advisor run, drowning out real findings.
--
-- Effect:
--   - Recreate each function with SET search_path = '' and schema-qualified
--     `public.<table>` references.
--   - Triggers stay attached because we use CREATE OR REPLACE FUNCTION; no
--     trigger DROP/CREATE needed.
--   - Behaviour byte-for-byte equivalent to the originals.
--
-- Idempotent.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. sync_display_name_from_full_name (BEFORE INSERT/UPDATE on profiles)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.sync_display_name_from_full_name()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF NEW.full_name IS NOT NULL
     AND NEW.full_name <> ''
     AND NEW.display_name IS NULL THEN
    NEW.display_name := NEW.full_name;
  END IF;
  RETURN NEW;
END;
$$;


-- ---------------------------------------------------------------------------
-- 2. update_marketplace_listings_updated_at (BEFORE UPDATE on marketplace_listings)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.update_marketplace_listings_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


-- ---------------------------------------------------------------------------
-- 3. update_conversations_updated_at (BEFORE UPDATE on conversations)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.update_conversations_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


-- ---------------------------------------------------------------------------
-- 4. update_conversation_last_message (AFTER INSERT on messages)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  UPDATE public.conversations SET
    last_message_content = NEW.content,
    last_message_at = NEW.created_at,
    last_message_user_id = NEW.sender_id,
    updated_at = now()
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$;


-- ---------------------------------------------------------------------------
-- 5. update_conversation_participant_count
--    (AFTER INSERT/UPDATE/DELETE on conversation_participants)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.update_conversation_participant_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  UPDATE public.conversations SET
    participant_count = (
      SELECT COUNT(*) FROM public.conversation_participants
      WHERE conversation_id = COALESCE(NEW.conversation_id, OLD.conversation_id)
        AND is_left = false
    )
  WHERE id = COALESCE(NEW.conversation_id, OLD.conversation_id);
  RETURN COALESCE(NEW, OLD);
END;
$$;


-- ---------------------------------------------------------------------------
-- 6. sync_marketplace_listing_profile
--    (AFTER UPDATE OF display_name/full_name/avatar_url ON profiles)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.sync_marketplace_listing_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  UPDATE public.marketplace_listings
  SET
    username   = COALESCE(NEW.display_name, NEW.full_name,
                          split_part(NEW.email, '@', 1)),
    avatar_url = NEW.avatar_url
  WHERE user_id = NEW.id;
  RETURN NEW;
END;
$$;
