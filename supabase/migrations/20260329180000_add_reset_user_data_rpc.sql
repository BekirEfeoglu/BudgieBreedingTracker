-- Transaction-safe user data reset function.
-- Deletes all user data in FK-safe order within a single transaction.
-- Profile and auth records are preserved.
CREATE OR REPLACE FUNCTION reset_user_data(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verify caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM admin_users WHERE user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Unauthorized: admin access required';
  END IF;

  -- Delete in FK-safe order (deepest children first)
  DELETE FROM event_reminders WHERE user_id = target_user_id;
  DELETE FROM growth_measurements WHERE user_id = target_user_id;
  DELETE FROM health_records WHERE user_id = target_user_id;
  DELETE FROM chicks WHERE user_id = target_user_id;
  DELETE FROM eggs WHERE user_id = target_user_id;
  DELETE FROM incubations WHERE user_id = target_user_id;
  DELETE FROM breeding_pairs WHERE user_id = target_user_id;
  DELETE FROM birds WHERE user_id = target_user_id;
  DELETE FROM nests WHERE user_id = target_user_id;
  DELETE FROM events WHERE user_id = target_user_id;
  DELETE FROM notifications WHERE user_id = target_user_id;
  DELETE FROM notification_settings WHERE user_id = target_user_id;
  DELETE FROM photos WHERE user_id = target_user_id;
  DELETE FROM sync_metadata WHERE user_id = target_user_id;
  DELETE FROM genetics_history WHERE user_id = target_user_id;
  -- Profile preserved intentionally
END;
$$;

-- Only admins can call this function
REVOKE ALL ON FUNCTION reset_user_data(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION reset_user_data(uuid) TO authenticated;
