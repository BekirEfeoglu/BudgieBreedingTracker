-- ============================================================================
-- Community report aggregation + auto-flag
-- ============================================================================
-- Prior state: community_reports rows were inserted by users but never
-- reflected back on the target post. `community_posts.report_count` and
-- `is_reported` stayed at their defaults, so nothing downstream (admin
-- review queue, feed filter) could see escalating report pressure.
--
-- This migration:
--   1. Adds a UNIQUE constraint preventing the same user from reporting the
--      same target more than once (defense in depth; RLS already scopes
--      inserts to auth.uid()).
--   2. Adds an AFTER INSERT trigger on community_reports that:
--      - increments community_posts.report_count when target_type='post'
--      - marks the post as needs_review=true at REVIEW_THRESHOLD reports,
--        so the existing admin review queue (fetchPendingReview) picks it up
--   3. Adds an index on community_reports.target_id so the trigger's
--      COUNT() stays cheap as the table grows.
--
-- Thresholds are deliberately conservative (3 reports → review). Admins
-- still have final say via the existing `clearReviewFlag` / soft-delete
-- flow; the trigger only flags, it does not auto-delete.
-- ============================================================================

-- 1. Prevent duplicate reports from the same user for the same target.
-- Use a partial unique index so pre-existing duplicates (unlikely) don't
-- break the migration.
CREATE UNIQUE INDEX IF NOT EXISTS uq_community_reports_user_target
  ON public.community_reports (user_id, target_id, target_type);

-- 2. Speed up the aggregation subquery in the trigger.
CREATE INDEX IF NOT EXISTS idx_community_reports_target
  ON public.community_reports (target_id, target_type);

-- 3. Aggregation trigger.
CREATE OR REPLACE FUNCTION public.apply_community_report_aggregation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_review_threshold CONSTANT int := 3;
  v_new_count int;
BEGIN
  IF NEW.target_type = 'post' THEN
    UPDATE public.community_posts
       SET report_count = report_count + 1,
           is_reported = true,
           needs_review = CASE
             WHEN report_count + 1 >= v_review_threshold THEN true
             ELSE needs_review
           END
     WHERE id = NEW.target_id
     RETURNING report_count INTO v_new_count;

    IF v_new_count IS NULL THEN
      RAISE NOTICE 'Report inserted for unknown post % (orphaned report)',
        NEW.target_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_community_report_aggregation
  ON public.community_reports;

CREATE TRIGGER trg_community_report_aggregation
  AFTER INSERT ON public.community_reports
  FOR EACH ROW
  EXECUTE FUNCTION public.apply_community_report_aggregation();

COMMENT ON FUNCTION public.apply_community_report_aggregation() IS
  'Aggregates community_reports counts onto community_posts and raises '
  'needs_review when the report threshold is reached. Does NOT auto-delete; '
  'admin workflow via fetchPendingReview/clearReviewFlag remains authoritative.';
