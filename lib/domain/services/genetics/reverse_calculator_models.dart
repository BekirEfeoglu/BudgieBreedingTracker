import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

/// Represents a potential parent combination to produce a target offspring.
class ReverseCalculationResult {
  final ParentGenotype father;
  final ParentGenotype mother;
  final double probabilityMale;
  final double probabilityFemale;

  const ReverseCalculationResult({
    required this.father,
    required this.mother,
    required this.probabilityMale,
    required this.probabilityFemale,
  });

  /// Probability regardless of sex, assuming ~50/50 male/female split.
  double get probabilityAny => (probabilityMale + probabilityFemale) / 2;

  /// The highest available chance across overall, male-only, and female-only.
  double get maxProbability {
    final any = probabilityAny;
    final bySex = probabilityMale > probabilityFemale
        ? probabilityMale
        : probabilityFemale;
    return any > bySex ? any : bySex;
  }
}

/// Internal locus-level result used during reverse calculation.
class LocusPairResult {
  final Map<String, AlleleState> fatherGenotype;
  final Map<String, AlleleState> motherGenotype;
  final double probabilityMale;
  final double probabilityFemale;

  const LocusPairResult({
    required this.fatherGenotype,
    required this.motherGenotype,
    required this.probabilityMale,
    required this.probabilityFemale,
  });
}
