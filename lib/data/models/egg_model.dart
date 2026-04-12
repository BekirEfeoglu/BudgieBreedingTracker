import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
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
    @JsonKey(unknownEnumValue: EggStatus.laid)
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
    return end.difference(layDate).inDays;
  }

  DateTime expectedHatchDateFor({Species species = Species.unknown}) =>
      layDate.add(Duration(days: totalIncubationDays(species: species)));

  DateTime get expectedHatchDate => expectedHatchDateFor();

  bool isOverdueFor({Species species = Species.unknown}) =>
      !isHatched &&
      DateTime.now().difference(layDate).inDays >
          totalIncubationDays(species: species);

  bool get isOverdue => isOverdueFor();

  double progressPercentFor({Species species = Species.unknown}) {
    final days = DateTime.now().difference(layDate).inDays;
    final percent = days / totalIncubationDays(species: species);
    return percent.clamp(0.0, 1.0);
  }

  double get progressPercent => progressPercentFor();

  bool get isHatched => status == EggStatus.hatched;
  bool get isFertile =>
      status == EggStatus.fertile || status == EggStatus.hatched;
  bool get isIncubating => status == EggStatus.incubating;
}
