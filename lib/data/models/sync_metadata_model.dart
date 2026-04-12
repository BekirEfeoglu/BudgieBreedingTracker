import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_metadata_model.freezed.dart';
part 'sync_metadata_model.g.dart';

enum SyncStatus {
  pending,

  /// Not actively used — successful push deletes the metadata record entirely.
  synced,

  error,

  /// Used by Incubation, Notification, GrowthMeasurement repositories
  /// for hard-delete sync (push deletion to server then remove locally).
  pendingDelete;

  String toJson() => name;
  static SyncStatus fromJson(String json) => values.byName(json);
}

@freezed
abstract class SyncMetadata with _$SyncMetadata {
  const SyncMetadata._();
  const factory SyncMetadata({
    required String id,
    @JsonKey(name: 'table_name') required String table,
    required String userId,
    @Default(SyncStatus.pending)
    @JsonKey(unknownEnumValue: SyncStatus.pending)
    SyncStatus status,
    String? recordId,
    String? errorMessage,
    int? retryCount,
    DateTime? lastSyncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SyncMetadata;

  factory SyncMetadata.fromJson(Map<String, dynamic> json) =>
      _$SyncMetadataFromJson(json);
}
