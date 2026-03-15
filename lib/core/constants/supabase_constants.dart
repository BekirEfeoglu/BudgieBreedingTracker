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
  static const String communityEventsTable = 'community_events';
  static const String communityEventAttendeesTable = 'community_event_attendees';
  static const String communityPollsTable = 'community_polls';
  static const String communityPollOptionsTable = 'community_poll_options';
  static const String communityPollVotesTable = 'community_poll_votes';
  static const String communityStoriesTable = 'community_stories';
  static const String communityStoryViewsTable = 'community_story_views';
  static const String calendarTable = 'calendar';
  static const String deletedEggsTable = 'deleted_eggs';
  static const String eggArchivesTable = 'egg_archives';
  static const String eventTypesTable = 'event_types';
  static const String eventTemplatesTable = 'event_templates';
  static const String adminSessionsTable = 'admin_sessions';
  static const String adminRateLimitsTable = 'admin_rate_limits';
  static const String backupSettingsTable = 'backup_settings';

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

  // Privacy & audit tables (no client remote source yet)
  static const String privacySettingsTable = 'privacy_settings';
  static const String privacyAuditLogsTable = 'privacy_audit_logs';
  static const String auditLogsTable = 'audit_logs';

  // Server-side logging & backup (no client remote source yet)
  static const String errorLogsTable = 'error_logs';
  static const String backupHistoryTable = 'backup_history';
  static const String configBackupsTable = 'config_backups';

  // Storage Buckets
  static const String birdPhotosBucket = 'bird-photos';
  static const String eggPhotosBucket = 'egg-photos';
  static const String chickPhotosBucket = 'chick-photos';
  static const String avatarsBucket = 'avatars';
  static const String backupsBucket = 'backups';
  // Requires manual creation in Supabase Dashboard:
  // RLS: authenticated users can INSERT, public can SELECT
  static const String communityPhotosBucket = 'community-photos';
}
