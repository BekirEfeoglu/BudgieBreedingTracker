import '../../../core/constants/supabase_constants.dart';

/// Centralized constants for the admin panel.
/// Replaces magic numbers scattered across admin files.
abstract final class AdminConstants {
  // Role values (admin_users.role column)
  static const String roleFounder = 'founder';
  static const String roleAdmin = 'admin';

  // Subscription plan values
  static const String planPremium = 'premium';
  static const String planFree = 'free';

  // Subscription status values
  static const String statusActive = 'active';
  static const String statusRevoked = 'revoked';
  static const String statusFree = 'free';

  // Pagination
  static const int usersPageSize = 50;
  static const int auditLogsPageSize = 100;
  static const int securityEventsPageSize = 100;
  static const int feedbackPageSize = 50;

  // Export
  static const int exportChunkSize = 500;
  static const int maxExportRows = 50000;

  // Retention
  static const int auditLogRetentionDays = 90;

  // Capacity thresholds
  static const double capacityWarningPercent = 0.9;
  static const double healthyThreshold = 0.7;
  static const double warningThreshold = 0.9;

  // DB size limits by Supabase plan (bytes)
  static const Map<String, int> dbSizeLimitByPlan = {
    'free': 500 * 1024 * 1024, // 500 MB
    'pro': 8 * 1024 * 1024 * 1024, // 8 GB
    'team': 8 * 1024 * 1024 * 1024, // 8 GB
    'enterprise': 16 * 1024 * 1024 * 1024, // 16 GB
  };
  static const int dbSizeLimitDefault = 8 * 1024 * 1024 * 1024; // 8 GB

  /// Returns DB size limit for the given Supabase plan name.
  static int dbSizeLimitForPlan(String plan) =>
      dbSizeLimitByPlan[plan.toLowerCase()] ?? dbSizeLimitDefault;

  // Debounce
  static const Duration searchDebounceDuration = Duration(milliseconds: 350);

  // Auto-refresh
  static const Duration monitoringRefreshInterval = Duration(seconds: 30);

  // Limits
  static const int recentActionsLimit = 5;
  static const int userActivityLogsLimit = 20;
  static const int maxAlertsLimit = 10;

  // Responsive breakpoints
  static const double wideLayoutBreakpoint = 840.0;
  static const double gridColumnBreakpoint = 600.0;

  // UI
  static const double gridAspectRatioWide = 1.4;
  static const double gridAspectRatioNarrow = 1.15;

  // Analytics
  static const int chartPeriodDays = 30;
  static const int topUsersLimit = 5;

  // Maintenance
  static const int defaultCleanupDays = 30;
  static const List<int> cleanupDayOptions = [7, 14, 30, 60, 90];

  // Soft-deletable tables (user data tables with is_deleted column)
  static const List<String> softDeletableTables = [
    SupabaseConstants.birdsTable,
    SupabaseConstants.breedingPairsTable,
    SupabaseConstants.nestsTable,
    SupabaseConstants.clutchesTable,
    SupabaseConstants.eggsTable,
    SupabaseConstants.chicksTable,
    SupabaseConstants.eventsTable,
    SupabaseConstants.eventRemindersTable,
    SupabaseConstants.healthRecordsTable,
    SupabaseConstants.notificationsTable,
    SupabaseConstants.photosTable,
  ];

  /// FK-safe deletion order for user data: children before parents.
  /// Single source of truth — used by DatabaseManager and BulkManager.
  static const List<String> userDataDeletionOrder = [
    SupabaseConstants.eventRemindersTable,
    SupabaseConstants.notificationSchedulesTable,
    SupabaseConstants.notificationsTable,
    SupabaseConstants.notificationSettingsTable,
    SupabaseConstants.photosTable,
    SupabaseConstants.growthMeasurementsTable,
    SupabaseConstants.healthRecordsTable,
    SupabaseConstants.eventsTable,
    SupabaseConstants.chicksTable,
    SupabaseConstants.eggsTable,
    SupabaseConstants.incubationsTable,
    SupabaseConstants.clutchesTable,
    SupabaseConstants.breedingPairsTable,
    SupabaseConstants.nestsTable,
    SupabaseConstants.birdsTable,
    SupabaseConstants.userPreferencesTable,
    SupabaseConstants.feedbackTable,
  ];

  // Storage buckets
  static const List<String> storageBuckets = [
    SupabaseConstants.birdPhotosBucket,
    SupabaseConstants.eggPhotosBucket,
    SupabaseConstants.chickPhotosBucket,
    SupabaseConstants.avatarsBucket,
    SupabaseConstants.backupsBucket,
  ];
}
