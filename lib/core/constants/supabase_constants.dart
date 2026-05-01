abstract class SupabaseConstants {
  // Tables
  static const String birdsTable = 'birds';
  static const String eggsTable = 'eggs';
  static const String chicksTable = 'chicks';
  static const String incubationsTable = 'incubations';
  static const String clutchesTable = 'clutches';
  static const String breedingPairsTable = 'breeding_pairs';
  static const String nestsTable = 'nests';
  static const String eventsTable = 'events';
  static const String healthRecordsTable = 'health_records';
  static const String growthMeasurementsTable = 'growth_measurements';
  static const String notificationsTable = 'notifications';
  static const String notificationSettingsTable = 'notification_settings';
  static const String profilesTable = 'profiles';
  static const String userPreferencesTable = 'user_preferences';
  static const String subscriptionPlansTable = 'subscription_plans';
  static const String userSubscriptionsTable = 'user_subscriptions';
  static const String photosTable = 'photos';
  static const String backupJobsTable = 'backup_jobs';
  static const String adminLogsTable = 'admin_logs';
  static const String adminUsersTable = 'admin_users';
  static const String securityEventsTable = 'security_events';
  static const String systemSettingsTable = 'system_settings';
  static const String systemMetricsTable = 'system_metrics';
  static const String systemStatusTable = 'system_status';
  static const String systemAlertsTable = 'system_alerts';
  static const String userSessionsTable = 'user_sessions';
  static const String eventRemindersTable = 'event_reminders';
  static const String notificationSchedulesTable = 'notification_schedules';
  static const String syncMetadataTable = 'sync_metadata';
  static const String geneticsHistoryTable = 'genetics_history';
  static const String feedbackTable = 'feedback';
  static const String communityPostsTable = 'community_posts';
  static const String communityCommentsTable = 'community_comments';
  static const String communityLikesTable = 'community_likes';
  static const String communityBookmarksTable = 'community_bookmarks';
  static const String communityCommentLikesTable = 'community_comment_likes';
  static const String communityFollowsTable = 'community_follows';
  static const String communityReportsTable = 'community_reports';
  static const String communityBlocksTable = 'community_blocks';
  static const String communityEventsTable = 'community_events';
  static const String communityEventAttendeesTable =
      'community_event_attendees';
  static const String communityPollsTable = 'community_polls';
  static const String communityPollOptionsTable = 'community_poll_options';
  static const String communityPollVotesTable = 'community_poll_votes';
  static const String communityStoriesTable = 'community_stories';
  static const String communityStoryViewsTable = 'community_story_views';

  // Marketplace
  static const String marketplaceListingsTable = 'marketplace_listings';
  static const String marketplaceFavoritesTable = 'marketplace_favorites';

  // Messaging
  static const String conversationsTable = 'conversations';
  static const String conversationParticipantsTable =
      'conversation_participants';
  static const String messagesTable = 'messages';

  // Gamification
  static const String badgesTable = 'badges';
  static const String userBadgesTable = 'user_badges';
  static const String userLevelsTable = 'user_levels';
  static const String xpTransactionsTable = 'xp_transactions';

  static const String calendarTable = 'calendar';
  static const String deletedEggsTable = 'deleted_eggs';
  static const String eggArchivesTable = 'egg_archives';
  static const String eventTypesTable = 'event_types';
  static const String eventTemplatesTable = 'event_templates';
  static const String adminSessionsTable = 'admin_sessions';
  static const String adminRateLimitsTable = 'admin_rate_limits';
  static const String backupSettingsTable = 'backup_settings';
  static const String mfaLockoutsTable = 'mfa_lockouts';
  static const String dbMonitoringSnapshotsTable = 'db_monitoring_snapshots';

  // Push notification tables (server-side, no client remote source yet)
  static const String fcmTokensTable = 'fcm_tokens';
  static const String webPushSubscriptionsTable = 'web_push_subscriptions';
  static const String notificationHistoryTable = 'notification_history';
  static const String notificationRateLimitsTable = 'notification_rate_limits';

  // Archive tables (no client remote source yet)
  static const String archivedBirdsTable = 'archived_birds';
  static const String archivedBreedingPairsTable = 'archived_breeding_pairs';
  static const String archivedClutchesTable = 'archived_clutches';
  static const String archivedEggsTable = 'archived_eggs';
  static const String archivedChicksTable = 'archived_chicks';
  static const String archiveJobsTable = 'archive_jobs';
  static const String archiveSettingsTable = 'archive_settings';

  // Common columns (shared across most tables)
  static const String colUserId = 'user_id';
  static const String colIsDeleted = 'is_deleted';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colId = 'id';
  static const String colStatus = 'status';
  static const String colRole = 'role';
  static const String colName = 'name';
  static const String colDate = 'date';
  static const String colNeedsReview = 'needs_review';
  static const String colGender = 'gender';

  // Foreign-key columns (shared across multiple tables)
  static const String colBirdId = 'bird_id';
  static const String colChickId = 'chick_id';
  static const String colClutchId = 'clutch_id';
  static const String colPostId = 'post_id';
  static const String colBreedingPairId = 'breeding_pair_id';

  // Entity-specific date columns
  static const String colHatchDate = 'hatch_date';
  static const String colMeasurementDate = 'measurement_date';
  static const String colStartDate = 'start_date';

  // Marketplace filter columns
  static const String colCity = 'city';
  static const String colListingType = 'listing_type';
  static const String colPrice = 'price';

  // Feedback columns
  static const String feedbackColId = 'id';
  static const String feedbackColUserId = 'user_id';
  static const String feedbackColType = 'type';
  static const String feedbackColSubject = 'subject';
  static const String feedbackColMessage = 'message';
  static const String feedbackColEmail = 'email';
  static const String feedbackColAppVersion = 'app_version';
  static const String feedbackColPlatform = 'platform';
  static const String feedbackColStatus = 'status';
  static const String feedbackColPriority = 'priority';
  static const String feedbackColAdminResponse = 'admin_response';
  static const String feedbackColCategory = 'category';
  static const String feedbackColAssignedAdminId = 'assigned_admin_id';
  static const String feedbackColInternalNote = 'internal_note';
  static const String feedbackColCreatedAt = 'created_at';
  // Notification columns (used by feedback founder notifications)
  static const String notificationColId = 'id';
  static const String notificationColUserId = 'user_id';
  static const String notificationColTitle = 'title';
  static const String notificationColBody = 'body';
  static const String notificationColType = 'type';
  static const String notificationColPriority = 'priority';
  static const String notificationColRead = 'read';
  static const String notificationColReferenceId = 'reference_id';
  static const String notificationColReferenceType = 'reference_type';
  static const String notificationColCreatedAt = 'created_at';
  static const String notificationColUpdatedAt = 'updated_at';

  // Storage Buckets
  static const String birdPhotosBucket = 'bird-photos';
  static const String eggPhotosBucket = 'egg-photos';
  static const String chickPhotosBucket = 'chick-photos';
  static const String avatarsBucket = 'avatars';
  static const String backupsBucket = 'backups';
  // Requires manual creation in Supabase Dashboard:
  // RLS: authenticated users can INSERT, public can SELECT
  static const String communityPhotosBucket = 'community-photos';
  static const String marketplacePhotosBucket = 'photos';
  static const String messagePhotosBucket = 'message-photos';
}
