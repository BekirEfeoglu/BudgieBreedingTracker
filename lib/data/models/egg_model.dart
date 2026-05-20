import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/date_utils.dart' as date_utils;
import 'package:budgie_breeding_tracker/domain/services/incubation/species_incubation_config.dart';

part 'egg_model.freezed.dart';
part 'egg_model.g.dart';

@freezed
abstract class Egg with _$Egg {
  const Egg._();

  const factory Egg({
    required String id,
    required DateTime layDate,
    required String userId,
    @Default(EggStatus.laid)
    @JsonKey(unknownEnumValue: EggStatus.unknown)
    EggStatus status,
    String? clutchId,
    String? incubationId,
    int? eggNumber,
    String? notes,
    String? photoUrl,
    DateTime? hatchDate,
    DateTime? fertileCheckDate,
    DateTime? discardDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isDeleted,
  }) = _Egg;

  factory Egg.fromJson(Map<String, dynamic> json) => _$EggFromJson(json);
}

extension EggX on Egg {
  int totalIncubationDays({Species species = Species.unknown}) =>
      incubationDaysForSpecies(species);

  int get incubationDays {
    final end = hatchDate ?? DateTime.now();
    return date_utils.DateUtils.dayDiff(layDate, end);
  }

  /// Returns the expected hatch date for this egg in the requested
  /// species. The lay date is normalized to UTC midnight first so the
  /// downstream `DateUtils.dayDiff` (which itself normalizes to UTC
  /// midnight) is comparing apples to apples — a `layDate` recorded at
  /// 23:30 local plus 18 days would otherwise sit at 23:30 local on
  /// day 18 and trip the overdue check ~1 hour after midnight on
  /// day 19, producing a 1-day false-overdue.
  DateTime expectedHatchDateFor({Species species = Species.unknown}) {
    final start = DateTime.utc(layDate.year, layDate.month, layDate.day);
    return start.add(Duration(days: totalIncubationDays(species: species)));
  }

  DateTime get expectedHatchDate => expectedHatchDateFor();

  bool isOverdueFor({Species species = Species.unknown}) =>
      !isHatched &&
      date_utils.DateUtils.dayDiff(layDate, DateTime.now()) >
          totalIncubationDays(species: species);

  bool get isOverdue => isOverdueFor();

  double progressPercentFor({Species species = Species.unknown}) {
    final days = date_utils.DateUtils.dayDiff(layDate, DateTime.now());
    final percent = days / totalIncubationDays(species: species);
    return percent.clamp(0.0, 1.0);
  }

  double get progressPercent => progressPercentFor();

  bool get isHatched => status == EggStatus.hatched;
  bool get isFertile =>
      status == EggStatus.fertile || status == EggStatus.hatched;
  bool get isIncubating => status == EggStatus.incubating;
  bool get isActiveIncubationEgg =>
      status == EggStatus.incubating ||
      (incubationId != null &&
          (status == EggStatus.laid || status == EggStatus.fertile));
}
