import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';

part 'bird_model.freezed.dart';
part 'bird_model.g.dart';

@freezed
abstract class Bird with _$Bird {
  const Bird._();

  const factory Bird({
    required String id,
    required String name,
    @JsonKey(unknownEnumValue: BirdGender.unknown)
    required BirdGender gender,
    required String userId,
    @Default(BirdStatus.alive)
    @JsonKey(unknownEnumValue: BirdStatus.unknown)
    BirdStatus status,
    @Default(Species.budgie)
    @JsonKey(unknownEnumValue: Species.budgie)
    Species species,
    String? ringNumber,
    String? photoUrl,
    String? fatherId,
    String? motherId,
    @JsonKey(unknownEnumValue: BirdColor.unknown)
    BirdColor? colorMutation,
    String? cageNumber,
    String? notes,
    DateTime? birthDate,
    DateTime? deathDate,
    DateTime? soldDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isDeleted,
    /// JSON-encoded list of mutation IDs (e.g., ['blue', 'opaline']).
    List<String>? mutations,
    /// JSON-encoded map of mutationId -> alleleState (e.g., {'blue': 'visual'}).
    Map<String, String>? genotypeInfo,
  }) = _Bird;

  factory Bird.fromJson(Map<String, dynamic> json) => _$BirdFromJson(json);
}

extension BirdX on Bird {
  ({int years, int months, int days})? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    final years = now.year - birthDate!.year;
    final months = now.month - birthDate!.month;
    final days = now.day - birthDate!.day;

    int adjustedYears = years;
    int adjustedMonths = months;
    int adjustedDays = days;

    if (adjustedDays < 0) {
      adjustedMonths -= 1;
      adjustedDays += DateTime(now.year, now.month, 0).day;
    }
    if (adjustedMonths < 0) {
      adjustedYears -= 1;
      adjustedMonths += 12;
    }

    return (years: adjustedYears, months: adjustedMonths, days: adjustedDays);
  }

  bool get isAlive => status == BirdStatus.alive;
  bool get isMale => gender == BirdGender.male;
  bool get isFemale => gender == BirdGender.female;

}
