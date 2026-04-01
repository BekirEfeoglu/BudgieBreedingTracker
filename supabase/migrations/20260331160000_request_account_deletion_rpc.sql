-- Self-service account deletion function.
-- Deletes all user data in FK-safe order within a single transaction.
-- Caller must be the authenticated user requesting their own deletion.
-- Unlike admin reset_user_data, this also deletes the user's profile.
CREATE OR REPLACE FUNCTION request_account_deletion(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verify caller is deleting their own account
  IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Unauthorized: can only delete own account';
  END IF;

  -- Layer 7: deepest children
  DELETE FROM event_reminders WHERE user_id = p_user_id;
  DELETE FROM growth_measurements WHERE user_id = p_user_id;

  -- Layer 6: leaf entities
  DELETE FROM health_records WHERE user_id = p_user_id;
  DELETE FROM photos WHERE user_id = p_user_id;
  DELETE FROM notifications WHERE user_id = p_user_id;
  DELETE FROM notification_settings WHERE user_id = p_user_id;
  DELETE FROM notification_schedules WHERE user_id = p_user_id;
  DELETE FROM events WHERE user_id = p_user_id;

  -- Layer 5
  DELETE FROM chicks WHERE user_id = p_user_id;

  -- Layer 4
  DELETE FROM eggs WHERE user_id = p_user_id;

  -- Layer 3
  DELETE FROM incubations WHERE user_id = p_user_id;
  DELETE FROM clutches WHERE user_id = p_user_id;

  -- Layer 2
  DELETE FROM breeding_pairs WHERE user_id = p_user_id;

  -- Layer 1
  DELETE FROM birds WHERE user_id = p_user_id;
  DELETE FROM nests WHERE user_id = p_user_id;

  -- Community (deepest children first)
  DELETE FROM community_poll_votes WHERE user_id = p_user_id;
  DELETE FROM community_comment_likes WHERE user_id = p_user_id;
  DELETE FROM community_story_views WHERE user_id = p_user_id;
  DELETE FROM community_event_attendees WHERE user_id = p_user_id;
  DELETE FROM community_likes WHERE user_id = p_user_id;
  DELETE FROM community_bookmarks WHERE user_id = p_user_id;
  DELETE FROM community_reports WHERE user_id = p_user_id;
  DELETE FROM community_follows WHERE follower_id = p_user_id;
  DELETE FROM community_blocks WHERE user_id = p_user_id;
  DELETE FROM community_comments WHERE user_id = p_user_id;
  DELETE FROM community_poll_options WHERE poll_id IN (
    SELECT id FROM community_polls WHERE post_id IN (
      SELECT id FROM community_posts WHERE user_id = p_user_id
    )
  );
  DELETE FROM community_polls WHERE post_id IN (
    SELECT id FROM community_posts WHERE user_id = p_user_id
  );
  DELETE FROM community_stories WHERE user_id = p_user_id;
  DELETE FROM community_events WHERE user_id = p_user_id;
  DELETE FROM community_posts WHERE user_id = p_user_id;

  -- Feedback
  DELETE FROM feedback WHERE user_id = p_user_id;

  -- Supporting data
  DELETE FROM genetics_history WHERE user_id = p_user_id;
  DELETE FROM sync_metadata WHERE user_id = p_user_id;

  -- Profile (account deletion removes profile, unlike admin reset)
  DELETE FROM profiles WHERE id = p_user_id;
END;
$$;

-- Any authenticated user can call this function (RPC body enforces own-account check)
REVOKE ALL ON FUNCTION request_account_deletion(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION request_account_deletion(uuid) TO authenticated;
