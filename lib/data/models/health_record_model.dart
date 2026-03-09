import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_record_model.freezed.dart';
part 'health_record_model.g.dart';

enum HealthRecordType {
  checkup,
  illness,
  injury,
  vaccination,
  medication,
  death,
  unknown;

  String toJson() => name;
  static HealthRecordType fromJson(String json) {
    for (final value in values) {
      if (value.name == json) return value;
    }
    return unknown;
  }
}

@freezed
abstract class HealthRecord with _$HealthRecord {
  const HealthRecord._();
  const factory HealthRecord({
    required String id,
    required DateTime date,
    @JsonKey(unknownEnumValue: HealthRecordType.unknown)
    required HealthRecordType type,
    required String title,
    required String userId,
    String? birdId,
    String? description,
    String? treatment,
    String? veterinarian,
    String? notes,
    double? weight,
    double? cost,
    DateTime? followUpDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isDeleted,
  }) = _HealthRecord;

  factory HealthRecord.fromJson(Map<String, dynamic> json) =>
      _$HealthRecordFromJson(json);
}
