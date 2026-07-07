-- Harden threaded community comments and maintain direct reply counts.
--
-- parent_id already exists in the original community_comments migration for
-- clean installs. Keep this migration idempotent so it can also repair older
-- environments where the column or FK is missing.

ALTER TABLE public.community_comments
ADD COLUMN IF NOT EXISTS parent_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'community_comments_parent_id_fkey'
      AND conrelid = 'public.community_comments'::regclass
  ) THEN
    ALTER TABLE public.community_comments
    ADD CONSTRAINT community_comments_parent_id_fkey
    FOREIGN KEY (parent_id)
    REFERENCES public.community_comments(id)
    ON DELETE CASCADE
    NOT VALID;
  END IF;
END $$;

ALTER TABLE public.community_comments
VALIDATE CONSTRAINT community_comments_parent_id_fkey;

ALTER TABLE public.community_comments
ADD COLUMN IF NOT EXISTS reply_count integer NOT NULL DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'community_comments_reply_count_nonnegative'
      AND conrelid = 'public.community_comments'::regclass
  ) THEN
    ALTER TABLE public.community_comments
    ADD CONSTRAINT community_comments_reply_count_nonnegative
    CHECK (reply_count >= 0)
    NOT VALID;
  END IF;
END $$;

ALTER TABLE public.community_comments
VALIDATE CONSTRAINT community_comments_reply_count_nonnegative;

-- Existing clean installs already have idx_community_comments_parent. This
-- partial composite index serves active reply lookups ordered by creation time.
CREATE INDEX IF NOT EXISTS idx_community_comments_parent_active_created
ON public.community_comments (parent_id, created_at)
WHERE parent_id IS NOT NULL AND is_deleted = false;

WITH reply_counts AS (
  SELECT parent_id, count(*)::integer AS reply_count
  FROM public.community_comments
  WHERE parent_id IS NOT NULL
    AND is_deleted = false
  GROUP BY parent_id
),
desired_counts AS (
  SELECT comments.id, COALESCE(reply_counts.reply_count, 0) AS reply_count
  FROM public.community_comments AS comments
  LEFT JOIN reply_counts ON reply_counts.parent_id = comments.id
)
UPDATE public.community_comments AS comments
SET reply_count = desired_counts.reply_count
FROM desired_counts
WHERE comments.id = desired_counts.id
  AND comments.reply_count IS DISTINCT FROM desired_counts.reply_count;

CREATE OR REPLACE FUNCTION public.validate_community_comment_parent()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_parent_post_id uuid;
  v_parent_is_deleted boolean;
  v_cycle_detected boolean;
BEGIN
  IF NEW.parent_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.id IS NOT NULL AND NEW.parent_id = NEW.id THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'community_comment_parent_self_reference';
  END IF;

  SELECT parent.post_id, parent.is_deleted
  INTO v_parent_post_id, v_parent_is_deleted
  FROM public.community_comments AS parent
  WHERE parent.id = NEW.parent_id;

  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  IF v_parent_post_id IS DISTINCT FROM NEW.post_id THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'community_comment_parent_post_mismatch';
  END IF;

  IF v_parent_is_deleted THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'community_comment_parent_deleted';
  END IF;

  IF NEW.id IS NOT NULL THEN
    WITH RECURSIVE ancestors AS (
      SELECT parent.parent_id
      FROM public.community_comments AS parent
      WHERE parent.id = NEW.parent_id

      UNION ALL

      SELECT parent.parent_id
      FROM public.community_comments AS parent
      JOIN ancestors ON ancestors.parent_id = parent.id
      WHERE ancestors.parent_id IS NOT NULL
    )
    SELECT EXISTS (
      SELECT 1
      FROM ancestors
      WHERE parent_id = NEW.id
    )
    INTO v_cycle_detected;

    IF v_cycle_detected THEN
      RAISE EXCEPTION USING
        ERRCODE = '23514',
        MESSAGE = 'community_comment_parent_cycle';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_validate_community_comment_parent
ON public.community_comments;

CREATE TRIGGER trigger_validate_community_comment_parent
BEFORE INSERT OR UPDATE OF parent_id, post_id
ON public.community_comments
FOR EACH ROW
EXECUTE FUNCTION public.validate_community_comment_parent();

CREATE OR REPLACE FUNCTION public.update_comment_reply_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old_counted boolean := false;
  v_new_counted boolean := false;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_new_counted := NEW.parent_id IS NOT NULL AND NEW.is_deleted = false;

    IF v_new_counted THEN
      UPDATE public.community_comments
      SET reply_count = reply_count + 1
      WHERE id = NEW.parent_id;
    END IF;

    RETURN NULL;
  END IF;

  IF TG_OP = 'DELETE' THEN
    v_old_counted := OLD.parent_id IS NOT NULL AND OLD.is_deleted = false;

    IF v_old_counted THEN
      UPDATE public.community_comments
      SET reply_count = GREATEST(reply_count - 1, 0)
      WHERE id = OLD.parent_id;
    END IF;

    RETURN NULL;
  END IF;

  v_old_counted := OLD.parent_id IS NOT NULL AND OLD.is_deleted = false;
  v_new_counted := NEW.parent_id IS NOT NULL AND NEW.is_deleted = false;

  IF v_old_counted AND (
    NOT v_new_counted OR OLD.parent_id IS DISTINCT FROM NEW.parent_id
  ) THEN
    UPDATE public.community_comments
    SET reply_count = GREATEST(reply_count - 1, 0)
    WHERE id = OLD.parent_id;
  END IF;

  IF v_new_counted AND (
    NOT v_old_counted OR OLD.parent_id IS DISTINCT FROM NEW.parent_id
  ) THEN
    UPDATE public.community_comments
    SET reply_count = reply_count + 1
    WHERE id = NEW.parent_id;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_reply_count
ON public.community_comments;

CREATE TRIGGER trigger_update_reply_count
AFTER INSERT OR DELETE OR UPDATE OF parent_id, is_deleted
ON public.community_comments
FOR EACH ROW
EXECUTE FUNCTION public.update_comment_reply_count();
