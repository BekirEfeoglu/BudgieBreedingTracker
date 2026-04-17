-- ============================================================================
-- Re-moderate community posts on content edit
-- ============================================================================
-- Gap: `moderate-content` edge function is invoked only on post CREATE (from
-- lib/features/community/providers/community_create_providers.dart). If a
-- user edits a post after initial moderation passed, the new content is
-- never re-scanned — a clean post can be edited into abusive content and
-- stay in the feed until someone reports it.
--
-- This trigger flags any content/image update as needs_review=true, so the
-- existing admin review queue (fetchPendingReview) picks it up for manual
-- moderation. This is defense-in-depth; the client should also re-invoke
-- moderate-content on edit, but we cannot trust client enforcement.
--
-- Only fires when content or images actually changed (IS DISTINCT FROM),
-- to avoid false positives from unrelated updates (like_count bumps etc).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.flag_community_post_on_edit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.content IS DISTINCT FROM OLD.content
     OR NEW.image_urls IS DISTINCT FROM OLD.image_urls THEN
    NEW.needs_review := true;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_flag_community_post_on_edit ON public.community_posts;

CREATE TRIGGER trg_flag_community_post_on_edit
  BEFORE UPDATE ON public.community_posts
  FOR EACH ROW
  WHEN (NEW.content IS DISTINCT FROM OLD.content
        OR NEW.image_urls IS DISTINCT FROM OLD.image_urls)
  EXECUTE FUNCTION public.flag_community_post_on_edit();

-- Same protection for marketplace_listings where applicable.
-- Guard with existence check in case the column set differs in some envs.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'marketplace_listings'
      AND column_name = 'needs_review'
  ) THEN
    EXECUTE $func$
      CREATE OR REPLACE FUNCTION public.flag_marketplace_listing_on_edit()
      RETURNS TRIGGER
      LANGUAGE plpgsql
      SECURITY DEFINER
      SET search_path = public
      AS $body$
      BEGIN
        IF NEW.title IS DISTINCT FROM OLD.title
           OR NEW.description IS DISTINCT FROM OLD.description THEN
          NEW.needs_review := true;
        END IF;
        RETURN NEW;
      END;
      $body$;
    $func$;

    DROP TRIGGER IF EXISTS trg_flag_marketplace_listing_on_edit ON public.marketplace_listings;

    CREATE TRIGGER trg_flag_marketplace_listing_on_edit
      BEFORE UPDATE ON public.marketplace_listings
      FOR EACH ROW
      WHEN (NEW.title IS DISTINCT FROM OLD.title
            OR NEW.description IS DISTINCT FROM OLD.description)
      EXECUTE FUNCTION public.flag_marketplace_listing_on_edit();
  END IF;
END $$;
