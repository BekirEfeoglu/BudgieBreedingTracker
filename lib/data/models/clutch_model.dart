import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';

part 'clutch_model.freezed.dart';
part 'clutch_model.g.dart';

@freezed
abstract class Clutch with _$Clutch {
  const Clutch._();

  const factory Clutch({
    required String id,
    required String userId,
    String? name,
    String? breedingId,
    String? incubationId,
    String? maleBirdId,
    String? femaleBirdId,
    String? nestId,
    DateTime? pairDate,
    DateTime? startDate,
    DateTime? endDate,
    @Default(BreedingStatus.active)
    @JsonKey(unknownEnumValue: BreedingStatus.active)
    BreedingStatus status,
    String? notes,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Clutch;

  factory Clutch.fromJson(Map<String, dynamic> json) => _$ClutchFromJson(json);
}
