import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';

part 'conflict_history_model.freezed.dart';
part 'conflict_history_model.g.dart';

@freezed
abstract class ConflictHistory with _$ConflictHistory {
  const ConflictHistory._();

  const factory ConflictHistory({
    required String id,
    required String userId,
    required String tableName,
    required String recordId,
    required String description,
    @JsonKey(unknownEnumValue: ConflictType.unknown)
    required ConflictType conflictType,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) = _ConflictHistory;

  factory ConflictHistory.fromJson(Map<String, dynamic> json) =>
      _$ConflictHistoryFromJson(json);
}
