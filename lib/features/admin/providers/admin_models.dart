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
    @Default('') String eventType,
    String? userId,
    String? ipAddress,
    @JsonKey(fromJson: _jsonbToString) String? details,
    required DateTime createdAt,
  }) = _SecurityEvent;

  factory SecurityEvent.fromJson(Map<String, dynamic> json) =>
      _$SecurityEventFromJson(json);
}

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
