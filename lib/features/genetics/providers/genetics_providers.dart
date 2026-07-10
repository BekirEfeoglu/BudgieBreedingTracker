import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/lethal_combination_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_colors.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/genetic_charts.dart';

part 'genetics_parent_providers.dart';
part 'genetics_punnett_providers.dart';
part 'genetics_analysis_providers.dart';
part 'genetics_provider_helpers.dart';

/// Singleton instance of the Mendelian calculator.
final mendelianCalculatorProvider = Provider<MendelianCalculator>((ref) {
  return const MendelianCalculator();
});

// IMPROVED: run genetics calculation in isolate to avoid UI thread blocking
// for complex genotypes (8+ mutations). Uses compute() like reverse calculator.
// Returns the full OffspringCalculation (results + pruning diagnostics) so the
// UI can warn when the multi-locus result set was truncated (Q1).
OffspringCalculation _calculateDetailedInIsolate(
  ({
    Map<String, String> father,
    String fatherGender,
    Map<String, String> mother,
    String motherGender,
  })
  args,
) {
  final fatherMutations = args.father.map(
    (k, v) => MapEntry(k, AlleleState.values.byName(v)),
  );
  final motherMutations = args.mother.map(
    (k, v) => MapEntry(k, AlleleState.values.byName(v)),
  );
  const calculator = MendelianCalculator();
  return calculator.calculateDetailed(
    father: ParentGenotype(
      mutations: fatherMutations,
      gender: BirdGender.values.byName(args.fatherGender),
    ),
    mother: ParentGenotype(
      mutations: motherMutations,
      gender: BirdGender.values.byName(args.motherGender),
    ),
  );
}

/// Full offspring calculation (results + pruning diagnostics) from current
/// genotype selections. Uses an isolate for heavy computation.
final offspringCalculationProvider = FutureProvider<OffspringCalculation?>((
  ref,
) async {
  final father = ref.watch(fatherGenotypeProvider);
  final mother = ref.watch(motherGenotypeProvider);

  if (father.isEmpty && mother.isEmpty) return null;

  // Serialize ParentGenotype for isolate boundary crossing
  final args = (
    father: father.mutations.map((k, v) => MapEntry(k, v.name)),
    fatherGender: father.gender.name,
    mother: mother.mutations.map((k, v) => MapEntry(k, v.name)),
    motherGender: mother.gender.name,
  );

  return compute(_calculateDetailedInIsolate, args);
});

/// Calculated offspring results from current genotype selections. Derived from
/// [offspringCalculationProvider] so results and diagnostics share one compute.
final offspringResultsProvider = FutureProvider<List<OffspringResult>?>((
  ref,
) async {
  final calc = await ref.watch(offspringCalculationProvider.future);
  return calc?.results;
});

/// Pruning diagnostics for the current calculation, or `null` before results
/// resolve. Drives the "results truncated" coverage warning (Q1).
final pruningDiagnosticsProvider = Provider<PruningDiagnostics?>((ref) {
  return ref.watch(offspringCalculationProvider).asData?.value?.diagnostics;
});
