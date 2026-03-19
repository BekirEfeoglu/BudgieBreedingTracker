import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';

part 'epistasis_engine_resolution.dart';
part 'epistasis_engine_modifiers.dart';
part 'epistasis_engine_interactions.dart';

/// Result of compound phenotype resolution, including masked mutations.
class CompoundPhenotypeResult {
  /// The resolved compound phenotype name (e.g., "Albino", "Cobalt Opaline").
  final String name;

  /// Mutations masked by Ino that are genetically present but not visible.
  /// e.g., an Albino bird may carry Opaline, Dark Factor hidden under Ino.
  final List<String> maskedMutations;

  const CompoundPhenotypeResult({
    required this.name,
    this.maskedMutations = const [],
  });
}

/// Epistasis engine for resolving compound phenotype names
/// from multiple interacting mutations in budgies.
///
/// Handles gene interactions such as:
/// - Ino + Blue = Albino
/// - Ino + Green = Lutino
/// - Cinnamon + Ino = Lacewing
/// - Dark Factor dosage + Base Color = variety naming
/// - Violet + Blue + 1DF = Visual Violet
/// - Grey + Green = Grey-Green, Grey + Blue = Grey
/// - Yellowface Type 2 + Blue + Ino = Creamino
/// - Yellowface Type 1 DF = White-faced (paradoxical)
/// - Recessive Pied + Clearflight Pied = Dark-Eyed Clear
class EpistasisEngine {
  const EpistasisEngine();

  /// Resolves a compound phenotype name from a set of visual mutation IDs.
  ///
  /// Returns a human-readable compound name (e.g., "Cobalt Opaline Spangle")
  /// or "Normal" if no special epistatic naming applies.
  String resolveCompoundPhenotype(Set<String> visualMutations) {
    return resolveCompoundPhenotypeDetailed(visualMutations).name;
  }

  /// Resolves compound phenotype with detailed info including masked mutations.
  ///
  /// [doubleFactorIds] contains mutation IDs that are homozygous (double factor)
  /// in this particular offspring. Used for incomplete dominant special naming
  /// (e.g., Yellowface Type I DF -> Whitefaced paradox).
  CompoundPhenotypeResult resolveCompoundPhenotypeDetailed(
    Set<String> visualMutations, {
    Set<String> doubleFactorIds = const {},
  }) {
    return _resolveCompoundPhenotypeDetailed(
      visualMutations,
      doubleFactorIds: doubleFactorIds,
    );
  }

  /// Returns a list of epistatic interactions detected in the mutation set.
  List<EpistaticInteraction> getInteractions(Set<String> mutations) {
    return _getInteractions(mutations);
  }
}

/// Internal enum for base color series.
enum _BaseColor { green, blue }

/// Represents an epistatic interaction between mutations.
class EpistaticInteraction {
  /// IDs of the mutations involved in this interaction.
  final List<String> mutationIds;

  /// Name of the resulting compound phenotype.
  final String resultName;

  /// Human-readable description of the interaction.
  final String description;

  const EpistaticInteraction({
    required this.mutationIds,
    required this.resultName,
    required this.description,
  });
}
