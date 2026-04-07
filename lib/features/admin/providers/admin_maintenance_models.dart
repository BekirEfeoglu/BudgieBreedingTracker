import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_maintenance_models.freezed.dart';
part 'admin_maintenance_models.g.dart';

/// Orphan data summary for database maintenance.
@freezed
abstract class OrphanDataSummary with _$OrphanDataSummary {
  const OrphanDataSummary._();
  const factory OrphanDataSummary({
    @Default(0) int orphanEggs,
    @Default(0) int orphanChicks,
    @Default(0) int orphanReminders,
    @Default(0) int orphanHealthRecords,
  }) = _OrphanDataSummary;

  factory OrphanDataSummary.fromJson(Map<String, dynamic> json) =>
      _$OrphanDataSummaryFromJson(json);
}

/// Soft-delete statistics per table.
@freezed
abstract class SoftDeleteStats with _$SoftDeleteStats {
  const SoftDeleteStats._();
  const factory SoftDeleteStats({
    required String tableName,
    @Default(0) int deletedCount,
    @Default(0) int olderThanDaysCount,
  }) = _SoftDeleteStats;

  factory SoftDeleteStats.fromJson(Map<String, dynamic> json) =>
      _$SoftDeleteStatsFromJson(json);
}

/// Storage bucket usage info.
@freezed
abstract class BucketUsage with _$BucketUsage {
  const BucketUsage._();
  const factory BucketUsage({
    required String bucketName,
    @Default(0) int fileCount,
    @Default(0) int totalSizeBytes,
  }) = _BucketUsage;

  factory BucketUsage.fromJson(Map<String, dynamic> json) =>
      _$BucketUsageFromJson(json);
}

/// Sync metadata summary for maintenance dashboard.
@freezed
abstract class SyncStatusSummary with _$SyncStatusSummary {
  const SyncStatusSummary._();
  const factory SyncStatusSummary({
    @Default(0) int pendingCount,
    @Default(0) int errorCount,
    DateTime? oldestPendingAt,
  }) = _SyncStatusSummary;

  factory SyncStatusSummary.fromJson(Map<String, dynamic> json) =>
      _$SyncStatusSummaryFromJson(json);
}
