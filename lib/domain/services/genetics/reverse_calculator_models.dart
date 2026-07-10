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

  /// The highest available chance across male-only and female-only outcomes.
  ///
  /// `probabilityAny` is the mean of the two and cannot exceed `max(male,
  /// female)`, so ranking by `max(male, female)` is always the stricter and
  /// more informative signal — it tells the breeder the best sex-targeted
  /// scenario rather than the average.
  double get maxProbability =>
      probabilityMale > probabilityFemale ? probabilityMale : probabilityFemale;

  /// Total number of non-wildtype allele states the parents must carry.
  /// Fewer selections = a simpler, more accessible pairing.
  int get nonWildtypeStateCount =>
      father.mutations.length + mother.mutations.length;

  /// How many of those states must be *visual* birds (harder to source than a
  /// carrier/split of the same mutation).
  int get visualRequirementCount =>
      father.visualMutations.length + mother.visualMutations.length;

  /// Stable, order-independent string identity of this parent pairing. Used as
  /// the final deterministic tie-break key so identical inputs always sort the
  /// same way.
  String get canonicalSignature {
    String side(ParentGenotype g) {
      final parts = g.mutations.entries
          .map((e) => '${e.key}=${e.value.name}')
          .toList()
        ..sort();
      return parts.join(',');
    }

    return 'F(${side(father)})M(${side(mother)})';
  }

  /// Deterministic total ordering for reverse results (Q3 tie-break contract).
  ///
  /// A result never loses to another except on a strict tie of the higher key,
  /// so the top-of-list guarantee is: best sex-targeted chance first, then best
  /// any-sex chance, then the simplest pairing, then the fewest visual
  /// requirements, then a stable alphabetical signature. Identical input +
  /// engine version therefore yields the same ordered results every run.
  static int compare(ReverseCalculationResult a, ReverseCalculationResult b) {
    final byMax = b.maxProbability.compareTo(a.maxProbability);
    if (byMax != 0) return byMax;
    final byAny = b.probabilityAny.compareTo(a.probabilityAny);
    if (byAny != 0) return byAny;
    final byStates =
        a.nonWildtypeStateCount.compareTo(b.nonWildtypeStateCount);
    if (byStates != 0) return byStates;
    final byVisual =
        a.visualRequirementCount.compareTo(b.visualRequirementCount);
    if (byVisual != 0) return byVisual;
    return a.canonicalSignature.compareTo(b.canonicalSignature);
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
