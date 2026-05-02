-- Notify founder-role admins about newly submitted feedback without relying on
-- client-side admin_users reads or cross-user notification inserts.
--
-- Primary path: AFTER INSERT trigger on public.feedback, so notification
-- creation is atomic with feedback creation. The public RPC remains only as a
-- backward-compatible retry path for older clients; duplicate inserts are
-- prevented by a partial unique index.

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA private TO authenticated, service_role;

DROP FUNCTION IF EXISTS public.notify_founders_of_feedback(UUID, TEXT, TEXT);
DROP TRIGGER IF EXISTS trg_notify_founders_of_feedback ON public.feedback;
DROP FUNCTION IF EXISTS private.notify_founders_of_feedback_after_insert();

-- Existing duplicate founder feedback notifications would block the unique
-- index. Keep the oldest row per founder/feedback pair.
WITH ranked AS (
  SELECT
    ctid,
    ROW_NUMBER() OVER (
      PARTITION BY user_id, reference_type, reference_id
      ORDER BY created_at NULLS FIRST, id
    ) AS rn
  FROM public.notifications
  WHERE reference_type = 'feedback'
    AND reference_id IS NOT NULL
)
DELETE FROM public.notifications n
USING ranked r
WHERE n.ctid = r.ctid
  AND r.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS idx_notifications_feedback_reference_unique
ON public.notifications (user_id, reference_type, reference_id)
WHERE reference_type = 'feedback'
  AND reference_id IS NOT NULL;

CREATE OR REPLACE FUNCTION private.notify_founders_of_feedback(
  p_feedback_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller UUID;
  v_feedback_user_id UUID;
  v_feedback_subject TEXT;
  v_feedback_type TEXT;
  v_title TEXT;
BEGIN
  v_caller := auth.uid();

  IF p_feedback_id IS NULL THEN
    RAISE EXCEPTION 'Feedback id is required';
  END IF;

  SELECT f.user_id, f.subject, f.type
    INTO v_feedback_user_id, v_feedback_subject, v_feedback_type
  FROM public.feedback f
  WHERE f.id = p_feedback_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Feedback not found';
  END IF;

  IF v_caller IS NOT NULL AND v_caller IS DISTINCT FROM v_feedback_user_id THEN
    RAISE EXCEPTION 'Feedback not found for current user';
  END IF;

  v_title := LEFT(
    'New Feedback: ' || COALESCE(NULLIF(BTRIM(v_feedback_type), ''), 'general'),
    200
  );

  INSERT INTO public.notifications (
    id,
    user_id,
    title,
    body,
    type,
    priority,
    read,
    reference_id,
    reference_type
  )
  SELECT
    gen_random_uuid(),
    au.user_id,
    v_title,
    NULLIF(LEFT(BTRIM(COALESCE(v_feedback_subject, '')), 500), ''),
    'custom',
    'normal',
    FALSE,
    p_feedback_id::TEXT,
    'feedback'
  FROM public.admin_users au
  WHERE au.role = 'founder'
  ON CONFLICT (user_id, reference_type, reference_id)
    WHERE reference_type = 'feedback'
      AND reference_id IS NOT NULL
  DO NOTHING;
END;
$$;

REVOKE ALL ON FUNCTION private.notify_founders_of_feedback(UUID)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.notify_founders_of_feedback(UUID)
  TO authenticated, service_role;

CREATE OR REPLACE FUNCTION private.notify_founders_of_feedback_after_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM private.notify_founders_of_feedback(NEW.id);
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.notify_founders_of_feedback_after_insert()
  FROM PUBLIC, anon, authenticated;

CREATE TRIGGER trg_notify_founders_of_feedback
  AFTER INSERT ON public.feedback
  FOR EACH ROW
  EXECUTE FUNCTION private.notify_founders_of_feedback_after_insert();

CREATE OR REPLACE FUNCTION public.notify_founders_of_feedback(
  p_feedback_id UUID
)
RETURNS VOID
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.notify_founders_of_feedback(p_feedback_id);
$$;

REVOKE ALL ON FUNCTION public.notify_founders_of_feedback(UUID)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.notify_founders_of_feedback(UUID)
  TO authenticated, service_role;

COMMENT ON INDEX public.idx_notifications_feedback_reference_unique IS
  'Ensures founder feedback notifications are idempotent under concurrent '
  'trigger/RPC execution.';
COMMENT ON FUNCTION private.notify_founders_of_feedback_after_insert() IS
  'AFTER INSERT trigger for public.feedback. Creates founder notifications in '
  'the same transaction as feedback creation.';
COMMENT ON FUNCTION public.notify_founders_of_feedback(UUID) IS
  'Backward-compatible SECURITY INVOKER retry wrapper. Primary notification '
  'creation happens atomically in trg_notify_founders_of_feedback.';
