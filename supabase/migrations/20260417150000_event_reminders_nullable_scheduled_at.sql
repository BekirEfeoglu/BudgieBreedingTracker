-- =============================================================================
-- Migration: event_reminders.scheduled_at → nullable
-- Date: 2026-04-17
-- Problem:
--   The Drift client-side schema for event_reminders does not carry a
--   scheduled_at column. The original table (20260215234109) declared
--   scheduled_at TIMESTAMPTZ NOT NULL, so every client push failed with
--   23502 (not-null violation), silently marking sync entries as errored.
-- Fix:
--   Drop NOT NULL so the column becomes optional. Server-side consumers
--   (none currently) must handle NULL when reading. If the field is later
--   repurposed, the value can be computed from the associated event row.
-- =============================================================================

ALTER TABLE public.event_reminders
  ALTER COLUMN scheduled_at DROP NOT NULL;

COMMENT ON COLUMN public.event_reminders.scheduled_at IS
  'Optional precomputed reminder fire timestamp. May be NULL; callers should '
  'compute from events.event_date - INTERVAL minutes_before when absent.';
