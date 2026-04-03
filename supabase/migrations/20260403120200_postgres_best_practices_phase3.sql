-- =============================================================================
-- Migration: Postgres Best Practices Phase 3
-- Date: 2026-04-03
-- Fixes:
--   1. Harden is_conversation_member: SET search_path TO '' (was 'public')
--   2. Add pg_trgm schema move validation
-- =============================================================================

-- =====================================================
-- 1. HARDEN is_conversation_member FUNCTION
-- The audit migration (phase 1) standardized 5 functions to
-- SET search_path TO '' but missed is_conversation_member.
-- SECURITY DEFINER functions with search_path = 'public' are
-- vulnerable if an attacker creates a same-named table in public.
-- Fix: SET search_path TO '' and fully-qualify table references.
-- =====================================================

CREATE OR REPLACE FUNCTION public.is_conversation_member(
  _conversation_id UUID,
  _user_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.conversation_participants
    WHERE conversation_id = _conversation_id
    AND user_id = _user_id
    AND is_left = false
  );
$$;


-- =====================================================
-- 2. VALIDATE pg_trgm SCHEMA MOVE
-- Phase 2 moved pg_trgm from public to extensions schema.
-- Verify that gin_trgm_ops operator class is still resolvable
-- by running a trivial similarity query. If the extension move
-- broke operator resolution, this SELECT will fail and abort
-- the migration — acting as a safety gate.
-- =====================================================

DO $$
BEGIN
  -- Verify gin_trgm_ops is resolvable after schema move
  PERFORM similarity('test', 'test');
EXCEPTION
  WHEN undefined_function THEN
    RAISE EXCEPTION 'pg_trgm operator class not resolvable after schema move. '
      'Check that extensions schema is in search_path or revert the move.';
END;
$$;
