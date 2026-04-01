-- Self-service account deletion function.
-- Deletes all user data in FK-safe order within a single transaction.
-- Caller must be the authenticated user requesting their own deletion.
-- Unlike admin reset_user_data, this also deletes the user's profile.
CREATE OR REPLACE FUNCTION request_account_deletion(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Verify caller is deleting their own account
  IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Unauthorized: can only delete own account';
  END IF;

  -- Layer 7: deepest children
  DELETE FROM public.event_reminders WHERE user_id = p_user_id;
  DELETE FROM public.growth_measurements WHERE user_id = p_user_id;

  -- Layer 6: leaf entities
  DELETE FROM public.health_records WHERE user_id = p_user_id;
  DELETE FROM public.photos WHERE user_id = p_user_id;
  DELETE FROM public.notifications WHERE user_id = p_user_id;
  DELETE FROM public.notification_settings WHERE user_id = p_user_id;
  DELETE FROM public.notification_schedules WHERE user_id = p_user_id;
  DELETE FROM public.events WHERE user_id = p_user_id;

  -- Layer 5
  DELETE FROM public.chicks WHERE user_id = p_user_id;

  -- Layer 4
  DELETE FROM public.eggs WHERE user_id = p_user_id;
  DELETE FROM public.deleted_eggs WHERE user_id = p_user_id;

  -- Layer 3
  DELETE FROM public.incubations WHERE user_id = p_user_id;
  DELETE FROM public.clutches WHERE user_id = p_user_id;

  -- Layer 2
  DELETE FROM public.breeding_pairs WHERE user_id = p_user_id;

  -- Layer 1
  DELETE FROM public.birds WHERE user_id = p_user_id;
  DELETE FROM public.nests WHERE user_id = p_user_id;

  -- Community (deepest children first)
  DELETE FROM public.community_poll_votes WHERE user_id = p_user_id;
  DELETE FROM public.community_comment_likes WHERE user_id = p_user_id;
  DELETE FROM public.community_story_views WHERE user_id = p_user_id;
  DELETE FROM public.community_event_attendees WHERE user_id = p_user_id;
  DELETE FROM public.community_likes WHERE user_id = p_user_id;
  DELETE FROM public.community_bookmarks WHERE user_id = p_user_id;
  DELETE FROM public.community_reports WHERE user_id = p_user_id;
  DELETE FROM public.community_follows WHERE follower_id = p_user_id OR following_id = p_user_id;
  DELETE FROM public.community_blocks WHERE user_id = p_user_id OR blocked_user_id = p_user_id;
  DELETE FROM public.community_comments WHERE user_id = p_user_id;
  DELETE FROM public.community_poll_options WHERE poll_id IN (
    SELECT id FROM public.community_polls WHERE post_id IN (
      SELECT id FROM public.community_posts WHERE user_id = p_user_id
    )
  );
  DELETE FROM public.community_polls WHERE post_id IN (
    SELECT id FROM public.community_posts WHERE user_id = p_user_id
  );
  DELETE FROM public.community_stories WHERE user_id = p_user_id;
  DELETE FROM public.community_events WHERE user_id = p_user_id;
  DELETE FROM public.community_posts WHERE user_id = p_user_id;

  -- Feedback
  DELETE FROM public.feedback WHERE user_id = p_user_id;

  -- Supporting data
  DELETE FROM public.genetics_history WHERE user_id = p_user_id;
  DELETE FROM public.sync_metadata WHERE user_id = p_user_id;

  -- Device-specific settings and preferences
  DELETE FROM public.user_preferences WHERE user_id = p_user_id;
  DELETE FROM public.calendar WHERE user_id = p_user_id;
  DELETE FROM public.mfa_lockouts WHERE user_id = p_user_id;

  -- Profile (account deletion removes profile, unlike admin reset)
  DELETE FROM public.profiles WHERE id = p_user_id;

  -- Auth user (prevents re-login to an empty account).
  -- Supabase cascades auth.sessions, auth.refresh_tokens, auth.mfa_factors,
  -- auth.identities, etc. automatically via FK ON DELETE CASCADE.
  --
  -- IMPORTANT: This directly deletes from auth.users (Supabase-managed schema).
  -- Verified against Supabase GoTrue v2 FK cascade behaviour. If Supabase adds
  -- new FK-dependent tables in future versions, they will also be cascade-deleted.
  -- Consider migrating to Supabase Admin API (supabase.auth.admin.deleteUser())
  -- via an Edge Function if cascade scope needs tighter control.
  --
  -- NOTE: Storage bucket files (bird-photos, egg-photos, chick-photos, avatars,
  -- backups) are NOT cleaned up here — the client must call StorageService cleanup
  -- before invoking this RPC, or a scheduled cron job should purge orphaned files
  -- for deleted users. See W9 in code review.
  DELETE FROM auth.users WHERE id = p_user_id;
END;
$$;

-- Any authenticated user can call this function (RPC body enforces own-account check)
REVOKE ALL ON FUNCTION request_account_deletion(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION request_account_deletion(uuid) TO authenticated;
