-- =============================================================================
-- Migration: Postgres Best Practices Audit
-- Date: 2026-04-03
-- Fixes:
--   1. RLS policies: wrap auth.uid() with (select auth.uid()) for performance
--   2. Force RLS on 9 tables missing FORCE ROW LEVEL SECURITY
--   3. Functions: add search_path to 5 custom functions (security)
--   4. Missing FK indexes: conversations.creator_id, marketplace_listings.reviewed_by
--   5. Missing partial indexes on is_deleted columns (6 tables)
--   6. Remove duplicate permissive policy on system_status
-- =============================================================================

-- =====================================================
-- 1. RLS POLICY PERFORMANCE: auth.uid() -> (select auth.uid())
-- Wrapping auth.uid() in a subquery makes Postgres evaluate it once
-- instead of per-row, yielding 5-100x faster queries at scale.
-- =====================================================

-- --- marketplace_listings (4 policies) ---

DROP POLICY IF EXISTS "marketplace_listings_delete" ON marketplace_listings;
CREATE POLICY "marketplace_listings_delete" ON marketplace_listings
  FOR DELETE TO authenticated
  USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "marketplace_listings_insert" ON marketplace_listings;
CREATE POLICY "marketplace_listings_insert" ON marketplace_listings
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "marketplace_listings_public_read" ON marketplace_listings;
CREATE POLICY "marketplace_listings_public_read" ON marketplace_listings
  FOR SELECT TO authenticated
  USING (
    ((status = 'active' AND is_deleted = false AND needs_review = false)
     OR (user_id = (select auth.uid())))
  );

DROP POLICY IF EXISTS "marketplace_listings_update" ON marketplace_listings;
CREATE POLICY "marketplace_listings_update" ON marketplace_listings
  FOR UPDATE TO authenticated
  USING (user_id = (select auth.uid()));

-- --- marketplace_favorites (3 policies) ---

DROP POLICY IF EXISTS "marketplace_favorites_own_read" ON marketplace_favorites;
CREATE POLICY "marketplace_favorites_own_read" ON marketplace_favorites
  FOR SELECT TO authenticated
  USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "marketplace_favorites_own_insert" ON marketplace_favorites;
CREATE POLICY "marketplace_favorites_own_insert" ON marketplace_favorites
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "marketplace_favorites_own_delete" ON marketplace_favorites;
CREATE POLICY "marketplace_favorites_own_delete" ON marketplace_favorites
  FOR DELETE TO authenticated
  USING (user_id = (select auth.uid()));

-- --- conversations (3 policies) ---

DROP POLICY IF EXISTS "conversations_insert" ON conversations;
CREATE POLICY "conversations_insert" ON conversations
  FOR INSERT TO authenticated
  WITH CHECK (creator_id = (select auth.uid()));

DROP POLICY IF EXISTS "conversations_participant_read" ON conversations;
CREATE POLICY "conversations_participant_read" ON conversations
  FOR SELECT TO authenticated
  USING (is_conversation_member(id, (select auth.uid())));

DROP POLICY IF EXISTS "conversations_update" ON conversations;
CREATE POLICY "conversations_update" ON conversations
  FOR UPDATE TO authenticated
  USING (is_conversation_member(id, (select auth.uid())));

-- --- conversation_participants (4 policies) ---

DROP POLICY IF EXISTS "participants_own_read" ON conversation_participants;
CREATE POLICY "participants_own_read" ON conversation_participants
  FOR SELECT TO authenticated
  USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "participants_conversation_read" ON conversation_participants;
CREATE POLICY "participants_conversation_read" ON conversation_participants
  FOR SELECT TO authenticated
  USING (is_conversation_member(conversation_id, (select auth.uid())));

DROP POLICY IF EXISTS "participants_insert" ON conversation_participants;
CREATE POLICY "participants_insert" ON conversation_participants
  FOR INSERT TO authenticated
  WITH CHECK (
    (user_id = (select auth.uid()))
    OR (
      is_conversation_member(conversation_id, (select auth.uid()))
      AND EXISTS (
        SELECT 1 FROM conversation_participants cp
        WHERE cp.conversation_id = conversation_participants.conversation_id
          AND cp.user_id = (select auth.uid())
          AND cp.role = ANY (ARRAY['owner', 'admin'])
      )
    )
  );

DROP POLICY IF EXISTS "participants_update" ON conversation_participants;
CREATE POLICY "participants_update" ON conversation_participants
  FOR UPDATE TO authenticated
  USING (
    (user_id = (select auth.uid()))
    OR (
      is_conversation_member(conversation_id, (select auth.uid()))
      AND EXISTS (
        SELECT 1 FROM conversation_participants cp
        WHERE cp.conversation_id = conversation_participants.conversation_id
          AND cp.user_id = (select auth.uid())
          AND cp.role = ANY (ARRAY['owner', 'admin'])
      )
    )
  );

-- --- messages (4 policies) ---

DROP POLICY IF EXISTS "messages_delete" ON messages;
CREATE POLICY "messages_delete" ON messages
  FOR DELETE TO authenticated
  USING (sender_id = (select auth.uid()));

DROP POLICY IF EXISTS "messages_insert" ON messages;
CREATE POLICY "messages_insert" ON messages
  FOR INSERT TO authenticated
  WITH CHECK (
    sender_id = (select auth.uid())
    AND is_conversation_member(conversation_id, (select auth.uid()))
  );

DROP POLICY IF EXISTS "messages_participant_read" ON messages;
CREATE POLICY "messages_participant_read" ON messages
  FOR SELECT TO authenticated
  USING (is_conversation_member(conversation_id, (select auth.uid())));

DROP POLICY IF EXISTS "messages_update" ON messages;
CREATE POLICY "messages_update" ON messages
  FOR UPDATE TO authenticated
  USING (sender_id = (select auth.uid()));

-- --- user_badges (2 policies) ---

DROP POLICY IF EXISTS "user_badges_own_insert" ON user_badges;
CREATE POLICY "user_badges_own_insert" ON user_badges
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "user_badges_own_update" ON user_badges;
CREATE POLICY "user_badges_own_update" ON user_badges
  FOR UPDATE TO authenticated
  USING (user_id = (select auth.uid()));

-- --- user_levels (2 policies) ---

DROP POLICY IF EXISTS "user_levels_own_insert" ON user_levels;
CREATE POLICY "user_levels_own_insert" ON user_levels
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "user_levels_own_update" ON user_levels;
CREATE POLICY "user_levels_own_update" ON user_levels
  FOR UPDATE TO authenticated
  USING (user_id = (select auth.uid()));

-- --- xp_transactions (2 policies) ---

DROP POLICY IF EXISTS "xp_transactions_own_read" ON xp_transactions;
CREATE POLICY "xp_transactions_own_read" ON xp_transactions
  FOR SELECT TO authenticated
  USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "xp_transactions_own_insert" ON xp_transactions;
CREATE POLICY "xp_transactions_own_insert" ON xp_transactions
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (select auth.uid()));


-- =====================================================
-- 2. FORCE ROW LEVEL SECURITY on 9 tables
-- Without FORCE, table owners bypass RLS entirely.
-- =====================================================

ALTER TABLE badges FORCE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants FORCE ROW LEVEL SECURITY;
ALTER TABLE conversations FORCE ROW LEVEL SECURITY;
ALTER TABLE marketplace_favorites FORCE ROW LEVEL SECURITY;
ALTER TABLE marketplace_listings FORCE ROW LEVEL SECURITY;
ALTER TABLE messages FORCE ROW LEVEL SECURITY;
ALTER TABLE user_badges FORCE ROW LEVEL SECURITY;
ALTER TABLE user_levels FORCE ROW LEVEL SECURITY;
ALTER TABLE xp_transactions FORCE ROW LEVEL SECURITY;


-- =====================================================
-- 3. FUNCTION SEARCH_PATH: set search_path on 5 custom functions
-- Without search_path, functions may resolve objects from
-- unexpected schemas, creating a SQL injection vector.
-- =====================================================

-- guard_protected_role_premium_mutation (trigger function)
CREATE OR REPLACE FUNCTION public.guard_protected_role_premium_mutation()
  RETURNS trigger
  LANGUAGE plpgsql
  SET search_path TO ''
AS $function$
begin
  if old.role in ('founder', 'admin')
     and (
       new.is_premium is distinct from old.is_premium
       or coalesce(new.subscription_status, '') is distinct from coalesce(old.subscription_status, '')
     ) then
    raise exception using
      errcode = 'P0001',
      message = 'protected_role_premium_mutation',
      detail = 'Cannot change premium fields for founder/admin users';
  end if;

  return new;
end;
$function$;

-- handle_new_user (SECURITY DEFINER - critical to set search_path)
CREATE OR REPLACE FUNCTION public.handle_new_user()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
AS $function$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, display_name, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'display_name'),
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', NEW.email, ''),
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$function$;

-- update_conversation_last_message (trigger function)
CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
  RETURNS trigger
  LANGUAGE plpgsql
  SET search_path TO ''
AS $function$
BEGIN
  UPDATE public.conversations SET
    last_message_content = NEW.content,
    last_message_at = NEW.created_at,
    last_message_user_id = NEW.sender_id,
    updated_at = now()
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$function$;

-- update_conversation_participant_count (trigger function)
CREATE OR REPLACE FUNCTION public.update_conversation_participant_count()
  RETURNS trigger
  LANGUAGE plpgsql
  SET search_path TO ''
AS $function$
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
$function$;

-- update_conversations_updated_at (trigger function)
CREATE OR REPLACE FUNCTION public.update_conversations_updated_at()
  RETURNS trigger
  LANGUAGE plpgsql
  SET search_path TO ''
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$;

-- update_marketplace_listings_updated_at (trigger function)
CREATE OR REPLACE FUNCTION public.update_marketplace_listings_updated_at()
  RETURNS trigger
  LANGUAGE plpgsql
  SET search_path TO ''
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$;


-- =====================================================
-- 4. MISSING FK INDEXES
-- Postgres does NOT auto-index foreign keys.
-- Missing FK indexes cause slow JOINs and CASCADE operations.
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_conversations_creator_id
  ON conversations (creator_id);

CREATE INDEX IF NOT EXISTS idx_marketplace_listings_reviewed_by
  ON marketplace_listings (reviewed_by);


-- =====================================================
-- 5. MISSING PARTIAL INDEXES on is_deleted columns
-- Partial indexes are smaller and faster when queries always
-- filter by is_deleted = false (which this app does for all reads).
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_community_events_active
  ON community_events (user_id) WHERE (is_deleted = false);

CREATE INDEX IF NOT EXISTS idx_community_stories_active
  ON community_stories (user_id) WHERE (is_deleted = false);

CREATE INDEX IF NOT EXISTS idx_conversations_active
  ON conversations (creator_id) WHERE (is_deleted = false);

CREATE INDEX IF NOT EXISTS idx_genetics_history_active
  ON genetics_history (user_id) WHERE (is_deleted = false);

CREATE INDEX IF NOT EXISTS idx_marketplace_listings_active
  ON marketplace_listings (user_id) WHERE (is_deleted = false);

CREATE INDEX IF NOT EXISTS idx_messages_active
  ON messages (conversation_id, created_at DESC) WHERE (is_deleted = false);


-- =====================================================
-- 6. REMOVE DUPLICATE PERMISSIVE POLICY on system_status
-- system_status_all (ALL for authenticated, is_admin()) overlaps with
-- specific admin policies for DELETE/INSERT/UPDATE and public SELECT.
-- Multiple permissive policies are OR'd together, causing unnecessary
-- evaluation overhead.
-- =====================================================

DROP POLICY IF EXISTS "system_status_all" ON system_status;
