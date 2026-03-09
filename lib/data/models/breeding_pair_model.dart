import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';

part 'breeding_pair_model.freezed.dart';
part 'breeding_pair_model.g.dart';

@freezed
abstract class BreedingPair with _$BreedingPair {
  const BreedingPair._();
  const factory BreedingPair({
    required String id,
    required String userId,
    @Default(BreedingStatus.active)
    @JsonKey(unknownEnumValue: BreedingStatus.active)
    BreedingStatus status,
    String? maleId,
    String? femaleId,
    String? cageNumber,
    String? notes,
    DateTime? pairingDate,
    DateTime? separationDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isDeleted,
  }) = _BreedingPair;

  factory BreedingPair.fromJson(Map<String, dynamic> json) =>
      _$BreedingPairFromJson(json);
}
