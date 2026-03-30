import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/species_incubation_config.dart';

part 'incubation_model.freezed.dart';
part 'incubation_model.g.dart';

@freezed
abstract class Incubation with _$Incubation {
  const Incubation._();

  const factory Incubation({
    required String id,
    required String userId,
    @Default(Species.unknown)
    @JsonKey(unknownEnumValue: Species.unknown)
    Species species,
    @Default(IncubationStatus.active)
    @JsonKey(unknownEnumValue: IncubationStatus.active)
    IncubationStatus status,
    @Default(1) int version,
    String? clutchId,
    String? breedingPairId,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? expectedHatchDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Incubation;

  factory Incubation.fromJson(Map<String, dynamic> json) =>
      _$IncubationFromJson(json);
}

extension IncubationX on Incubation {
  int totalIncubationDays({Species? species}) => incubationDaysFromDates(
    startDate: startDate,
    expectedHatchDate: expectedHatchDate,
    species: species ?? this.species,
  );

  int get daysElapsed {
    if (startDate == null) return 0;
    final end = endDate ?? DateTime.now();
    return end.difference(startDate!).inDays;
  }

  int daysRemainingFor({Species? species}) {
    final remaining = totalIncubationDays(species: species) - daysElapsed;
    return remaining < 0 ? 0 : remaining;
  }

  int get daysRemaining => daysRemainingFor();

  double percentageCompleteFor({Species? species}) {
    if (startDate == null) return 0.0;
    final percent = daysElapsed / totalIncubationDays(species: species);
    return percent.clamp(0.0, 1.0);
  }

  double get percentageComplete => percentageCompleteFor();

  bool get isComplete => status == IncubationStatus.completed;
  bool get isActive => status == IncubationStatus.active;

  DateTime? computedExpectedHatchDateFor({Species? species}) {
    if (expectedHatchDate != null) return expectedHatchDate;
    if (startDate == null) return null;
    return startDate!.add(
      Duration(days: totalIncubationDays(species: species)),
    );
  }

  DateTime? get computedExpectedHatchDate => computedExpectedHatchDateFor();
}
