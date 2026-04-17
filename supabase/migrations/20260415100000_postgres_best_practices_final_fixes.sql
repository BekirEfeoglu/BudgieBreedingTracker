-- =============================================================================
-- Migration: Postgres Best Practices Final Fixes
-- Date: 2026-04-15
-- Fixes:
--   1. Fix sync_marketplace_listing_profile: add SET search_path TO ''
--   2. Drop duplicate index on community_posts (identical definitions)
--   3. Tighten storage bucket SELECT policies to prevent file listing
-- =============================================================================

-- =====================================================
-- 1. FIX FUNCTION search_path (Security Advisor WARN)
-- sync_marketplace_listing_profile is missing search_path,
-- which allows potential schema injection attacks.
-- =====================================================

CREATE OR REPLACE FUNCTION public.sync_marketplace_listing_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path TO ''
AS $$
BEGIN
  UPDATE public.marketplace_listings
  SET
    username = COALESCE(NEW.display_name, NEW.full_name, split_part(NEW.email, '@', 1)),
    avatar_url = NEW.avatar_url
  WHERE user_id = NEW.id;
  RETURN NEW;
END;
$$;


-- =====================================================
-- 2. DROP DUPLICATE INDEX (Performance Advisor WARN)
-- idx_community_posts_active and idx_community_posts_user_created
-- are identical: btree (user_id, created_at DESC) WHERE is_deleted = false
-- Keep the more descriptively named one.
-- =====================================================

DROP INDEX IF EXISTS idx_community_posts_user_created;


-- =====================================================
-- 3. TIGHTEN STORAGE BUCKET SELECT POLICIES (Security Advisor WARN)
-- Public buckets (avatars, photos) have broad SELECT policies that
-- allow listing ALL files. Public buckets serve files by URL without
-- needing a SELECT policy. Restrict to path-scoped access only.
-- =====================================================

-- avatars: replace broad SELECT with path-scoped policy
DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
CREATE POLICY "Scoped avatar read" ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] IS NOT NULL
  );

-- photos: replace broad SELECT with path-scoped policy
DROP POLICY IF EXISTS "Public read marketplace images" ON storage.objects;
CREATE POLICY "Scoped photos read" ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'photos'
    AND (storage.foldername(name))[1] = 'marketplace-images'
  );
