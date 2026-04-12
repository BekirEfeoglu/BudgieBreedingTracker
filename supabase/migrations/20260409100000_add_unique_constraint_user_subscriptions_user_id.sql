-- Add unconditional UNIQUE constraint on user_subscriptions.user_id
-- Previously only a partial unique index existed (WHERE status IN ('active','trial')),
-- which prevented PostgREST upsert with onConflict: 'user_id'.
--
-- This migration:
-- 1. Deduplicates any existing rows (keeps the latest per user_id)
-- 2. Adds a proper UNIQUE constraint (idempotent)
-- 3. Drops the now-redundant partial unique index

-- Step 1: Remove duplicates — keep only the most recently updated row per user_id.
-- Uses DISTINCT ON to deterministically pick exactly one row per user_id,
-- even when updated_at values are identical.
DELETE FROM user_subscriptions
WHERE id NOT IN (
  SELECT DISTINCT ON (user_id) id
  FROM user_subscriptions
  ORDER BY user_id, updated_at DESC NULLS LAST, created_at DESC NULLS LAST
);

-- Step 2: Add UNIQUE constraint (idempotent — skip if already exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'uq_user_subscriptions_user_id'
  ) THEN
    ALTER TABLE user_subscriptions
      ADD CONSTRAINT uq_user_subscriptions_user_id UNIQUE (user_id);
  END IF;
END $$;

-- Step 3: Drop the old partial unique index (the unconditional UNIQUE is stricter)
DROP INDEX IF EXISTS idx_user_subscriptions_active;
