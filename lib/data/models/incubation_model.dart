import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';

part 'incubation_model.freezed.dart';
part 'incubation_model.g.dart';

@freezed
abstract class Incubation with _$Incubation {
  const Incubation._();

  const factory Incubation({
    required String id,
    required String userId,
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
  int get daysElapsed {
    if (startDate == null) return 0;
    final end = endDate ?? DateTime.now();
    return end.difference(startDate!).inDays;
  }

  int get daysRemaining {
    final remaining = IncubationConstants.incubationPeriodDays - daysElapsed;
    return remaining < 0 ? 0 : remaining;
  }

  double get percentageComplete {
    if (startDate == null) return 0.0;
    final percent = daysElapsed / IncubationConstants.incubationPeriodDays;
    return percent.clamp(0.0, 1.0);
  }

  bool get isComplete => status == IncubationStatus.completed;
  bool get isActive => status == IncubationStatus.active;

  DateTime? get computedExpectedHatchDate {
    if (startDate == null) return null;
    return startDate!.add(
      const Duration(days: IncubationConstants.incubationPeriodDays),
    );
  }
}
