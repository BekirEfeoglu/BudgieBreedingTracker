import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';

enum GeneticsMode { full, limited, none }

class SpeciesProfile {
  final Species species;
  final String labelKey;
  final String helpTextKey;
  final GeneticsMode geneticsMode;
  final List<BirdColor> supportedColors;
  final int incubationPeriodDays;
  final int candlingDay;
  final int secondCheckDay;
  final int sensitivePeriodDay;
  final int expectedHatchDay;
  final int lateHatchDay;
  final List<String> eggTurningHours;

  const SpeciesProfile({
    required this.species,
    required this.labelKey,
    required this.helpTextKey,
    required this.geneticsMode,
    required this.supportedColors,
    required this.incubationPeriodDays,
    required this.candlingDay,
    required this.secondCheckDay,
    required this.sensitivePeriodDay,
    required this.expectedHatchDay,
    required this.lateHatchDay,
    required this.eggTurningHours,
  });

  bool get supportsGenetics => geneticsMode != GeneticsMode.none;
}
