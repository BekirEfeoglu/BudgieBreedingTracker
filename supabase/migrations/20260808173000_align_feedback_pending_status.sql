-- The admin feedback UI and API contract use `pending`, while the original
-- table constraint accepted the legacy `in_progress` value. Align the schema
-- before administrative updates can persist a pending status.

UPDATE public.feedback
SET status = 'pending'
WHERE status = 'in_progress';

ALTER TABLE public.feedback
  DROP CONSTRAINT IF EXISTS feedback_status_check;

ALTER TABLE public.feedback
  ADD CONSTRAINT feedback_status_check
  CHECK (status IN ('open', 'pending', 'resolved', 'closed', 'wont_fix'));
