import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/enums/admin_enums.dart';

part 'admin_models.freezed.dart';
part 'admin_models.g.dart';

/// Converts a jsonb value from Supabase to a readable String.
///
/// Handles: null, String, Map (extracts 'message' key), List, and other types.
String? _jsonbToString(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return raw;
  if (raw is Map) {
    if (raw.isEmpty) return null;
    return raw['message'] as String? ?? raw.toString();
  }
  if (raw is List) {
    if (raw.isEmpty) return null;
    return raw.join(', ');
  }
  return raw.toString();
}

/// Admin dashboard statistics.
@freezed
abstract class AdminStats with _$AdminStats {
  const AdminStats._();
  const factory AdminStats({
    @Default(0) int totalUsers,
    @Default(0) int activeToday,
    @Default(0) int newUsersToday,
    @Default(0) int totalBirds,
    @Default(0) int activeBreedings,
  }) = _AdminStats;

  factory AdminStats.fromJson(Map<String, dynamic> json) =>
      _$AdminStatsFromJson(json);
}

/// Minimal user model for admin list.
@freezed
abstract class AdminUser with _$AdminUser {
  const AdminUser._();
  const factory AdminUser({
    required String id,
    @Default('') String email,
    String? fullName,
    String? avatarUrl,
    required DateTime createdAt,
    @Default(true) bool isActive,
  }) = _AdminUser;

  factory AdminUser.fromJson(Map<String, dynamic> json) =>
      _$AdminUserFromJson(json);
}

/// Detailed user model for admin user detail screen.
@freezed
abstract class AdminUserDetail with _$AdminUserDetail {
  const AdminUserDetail._();
  const factory AdminUserDetail({
    required String id,
    @Default('') String email,
    String? fullName,
    String? avatarUrl,
    required DateTime createdAt,
    @Default(true) bool isActive,
    String? subscriptionPlan,
    String? subscriptionStatus,
    DateTime? subscriptionUpdatedAt,
    @Default(0) int birdsCount,
    @Default([]) List<AdminLog> activityLogs,
  }) = _AdminUserDetail;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) =>
      _$AdminUserDetailFromJson(json);
}

/// Admin log entry.
@freezed
abstract class AdminLog with _$AdminLog {
  const AdminLog._();
  const factory AdminLog({
    required String id,
    @Default('') String action,
    String? adminUserId,
    String? targetUserId,
    @JsonKey(fromJson: _jsonbToString) String? details,
    required DateTime createdAt,
  }) = _AdminLog;

  factory AdminLog.fromJson(Map<String, dynamic> json) =>
      _$AdminLogFromJson(json);
}

/// Security event entry.
@freezed
abstract class SecurityEvent with _$SecurityEvent {
  const SecurityEvent._();
  const factory SecurityEvent({
    required String id,
    @JsonKey(
      fromJson: SecurityEventType.fromJson,
      toJson: _securityEventTypeToJson,
    )
    @Default(SecurityEventType.unknown)
    SecurityEventType eventType,
    String? userId,
    String? ipAddress,
    @JsonKey(fromJson: _jsonbToString) String? details,
    required DateTime createdAt,
  }) = _SecurityEvent;

  factory SecurityEvent.fromJson(Map<String, dynamic> json) =>
      _$SecurityEventFromJson(json);

  /// Severity derived from event type.
  SecuritySeverityLevel get severity => eventType.inferredSeverity;
}

String _securityEventTypeToJson(SecurityEventType type) => type.toJson();

/// Database table info.
@freezed
abstract class TableInfo with _$TableInfo {
  const TableInfo._();
  const factory TableInfo({
    @JsonKey(name: 'table_name') @Default('') String name,
    @Default(0) int rowCount,
  }) = _TableInfo;

  factory TableInfo.fromJson(Map<String, dynamic> json) =>
      _$TableInfoFromJson(json);
}

/// System alert entry.
@freezed
abstract class SystemAlert with _$SystemAlert {
  const SystemAlert._();
  const factory SystemAlert({
    required String id,
    @Default('') String title,
    @Default('') String message,
    @Default(AlertSeverity.info)
    @JsonKey(unknownEnumValue: AlertSeverity.unknown)
    AlertSeverity severity,
    @Default('system') String alertType,
    @Default(true) bool isActive,
    @Default(false) bool isAcknowledged,
    required DateTime createdAt,
  }) = _SystemAlert;

  factory SystemAlert.fromJson(Map<String, dynamic> json) =>
      _$SystemAlertFromJson(json);
}

/// Server capacity metrics from PostgreSQL system catalogs.
@freezed
abstract class ServerCapacity with _$ServerCapacity {
  const ServerCapacity._();
  const factory ServerCapacity({
    @Default(0) int databaseSizeBytes,
    @Default(0) int activeConnections,
    @Default(0) int totalConnections,
    @Default(60) int maxConnections,
    @Default(0) double cacheHitRatio,
    @Default(0) int totalRows,
    @Default(0) double indexHitRatio,
    @Default([]) List<TableCapacity> tables,
  }) = _ServerCapacity;

  factory ServerCapacity.fromJson(Map<String, dynamic> json) =>
      _$ServerCapacityFromJson(json);

  double get connectionUsageRatio =>
      maxConnections > 0 ? totalConnections / maxConnections : 0;
}

/// Individual table capacity metrics.
@freezed
abstract class TableCapacity with _$TableCapacity {
  const TableCapacity._();
  const factory TableCapacity({
    @Default('') String name,
    @Default(0) int sizeBytes,
    @Default(0) int rowCount,
    @Default(0) int deadTupleCount,
    @Default(0) double deadTupleRatio,
    String? lastVacuum,
    String? lastAnalyze,
  }) = _TableCapacity;

  factory TableCapacity.fromJson(Map<String, dynamic> json) =>
      _$TableCapacityFromJson(json);
}

/// Query parameters for admin users list (server-side filtering).
@freezed
abstract class AdminUsersQuery with _$AdminUsersQuery {
  const AdminUsersQuery._();
  const factory AdminUsersQuery({
    @Default('') String searchTerm,
    @Default(null) bool? isActiveFilter,
    @Default('created_at') String sortField,
    @Default(false) bool sortAscending,
    @Default(50) int limit,
  }) = _AdminUsersQuery;

  factory AdminUsersQuery.fromJson(Map<String, dynamic> json) =>
      _$AdminUsersQueryFromJson(json);
}

/// Query parameters for admin feedback list (server-side filtering).
@freezed
abstract class FeedbackQuery with _$FeedbackQuery {
  const FeedbackQuery._();
  const factory FeedbackQuery({
    @Default(null) FeedbackStatus? statusFilter,
    @Default('') String searchQuery,
    @Default(50) int limit,
  }) = _FeedbackQuery;

  factory FeedbackQuery.fromJson(Map<String, dynamic> json) =>
      _$FeedbackQueryFromJson(json);
}

/// Typed model for admin system settings.
/// Replaces `Map<String, Map<String, dynamic>>` loose typing.
@freezed
abstract class AdminSystemSettings with _$AdminSystemSettings {
  const AdminSystemSettings._();
  const factory AdminSystemSettings({
    @Default(false) bool maintenanceMode,
    @Default(true) bool registrationOpen,
    @Default(true) bool emailVerificationRequired,
    @Default(true) bool premiumEnabled,
    @Default(true) bool rateLimitingEnabled,
    @Default(false) bool twoFactorRequired,
    @Default(false) bool autoBackupEnabled,
    @Default(false) bool autoCleanupEnabled,
    @Default(true) bool globalPushEnabled,
    @Default(true) bool emailAlertsEnabled,
    DateTime? lastUpdated,
  }) = _AdminSystemSettings;

  factory AdminSystemSettings.fromJson(Map<String, dynamic> json) =>
      _$AdminSystemSettingsFromJson(json);

  /// Build from the raw settings map returned by adminSystemSettingsProvider.
  factory AdminSystemSettings.fromSettingsMap(
    Map<String, Map<String, dynamic>> map,
  ) {
    bool val(String key, bool fallback) {
      final entry = map[key];
      if (entry == null) return fallback;
      final v = entry['value'];
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return fallback;
    }

    DateTime? latestUpdate;
    for (final entry in map.values) {
      final raw = entry['updated_at'] as String?;
      if (raw != null) {
        final dt = DateTime.tryParse(raw);
        if (dt != null && (latestUpdate == null || dt.isAfter(latestUpdate))) {
          latestUpdate = dt;
        }
      }
    }

    return AdminSystemSettings(
      maintenanceMode: val('maintenance_mode', false),
      registrationOpen: val('registration_open', true),
      emailVerificationRequired: val('email_verification_required', true),
      premiumEnabled: val('premium_enabled', true),
      rateLimitingEnabled: val('rate_limiting_enabled', true),
      twoFactorRequired: val('two_factor_required', false),
      autoBackupEnabled: val('auto_backup_enabled', false),
      autoCleanupEnabled: val('auto_cleanup_enabled', false),
      globalPushEnabled: val('global_push_enabled', true),
      emailAlertsEnabled: val('email_alerts_enabled', true),
      lastUpdated: latestUpdate,
    );
  }
}
