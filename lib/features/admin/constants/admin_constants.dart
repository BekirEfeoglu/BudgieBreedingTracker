/// Centralized constants for the admin panel.
/// Replaces magic numbers scattered across admin files.
abstract final class AdminConstants {
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
  static const int dbSizeLimitBytes = 8 * 1024 * 1024 * 1024; // 8 GB (Pro Plan)
  static const double healthyThreshold = 0.7;
  static const double warningThreshold = 0.9;

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
    'birds',
    'breeding_pairs',
    'nests',
    'clutches',
    'eggs',
    'chicks',
    'events',
    'event_reminders',
    'health_records',
    'photos',
  ];

  // Storage buckets
  static const List<String> storageBuckets = [
    'bird-photos',
    'egg-photos',
    'chick-photos',
    'avatars',
    'backups',
  ];
}
