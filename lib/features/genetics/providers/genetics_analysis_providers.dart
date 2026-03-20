part of 'genetics_providers.dart';

/// Chart data derived from offspring results for bar chart visualization.
final offspringChartDataProvider = Provider<List<GeneticChartItem>>((ref) {
  final results = ref.watch(offspringResultsProvider);
  if (results == null || results.isEmpty) return [];

  return results.map((r) {
    return GeneticChartItem(
      label: r.phenotype,
      value: r.probability * 100,
      color: r.visualMutations.isNotEmpty
          ? phenotypeColorFromMutations(r.visualMutations)
          : phenotypeColor(r.phenotype),
    );
  }).toList();
});

/// Singleton instance of the viability analyzer.
final viabilityAnalyzerProvider = Provider<ViabilityAnalyzer>((ref) {
  return const ViabilityAnalyzer();
});

/// Lethal combination analysis for current parent selections.
final lethalAnalysisProvider = Provider<LethalAnalysisResult?>((ref) {
  final results = ref.watch(offspringResultsProvider);
  if (results == null || results.isEmpty) return null;

  final fatherMutations = ref.watch(fatherMutationsProvider);
  final motherMutations = ref.watch(motherMutationsProvider);
  final analyzer = ref.watch(viabilityAnalyzerProvider);

  return analyzer.analyze(
    fatherMutations: fatherMutations,
    motherMutations: motherMutations,
    offspringResults: results,
  );
});

/// Offspring results enriched with lethal combination IDs for badge display.
final enrichedOffspringResultsProvider = Provider<List<OffspringResult>?>((
  ref,
) {
  final results = ref.watch(offspringResultsProvider);
  if (results == null) return null;

  final analysis = ref.watch(lethalAnalysisProvider);
  if (analysis == null || !analysis.hasWarnings) return results;

  return results.map((result) {
    final comboIds = analysis.warnings
        .where(
          (w) =>
              w.offspring.phenotype == result.phenotype &&
              w.offspring.sex == result.sex,
        )
        .map((w) => w.combination.id)
        .toSet()
        .toList();
    if (comboIds.isEmpty) return result;
    return OffspringResult(
      phenotype: result.phenotype,
      probability: result.probability,
      sex: result.sex,
      isCarrier: result.isCarrier,
      genotype: result.genotype,
      visualMutations: result.visualMutations,
      compoundPhenotype: result.compoundPhenotype,
      carriedMutations: result.carriedMutations,
      maskedMutations: result.maskedMutations,
      lethalCombinationIds: comboIds,
    );
  }).toList();
});

/// Epistatic interactions inferred from offspring mutation combinations.
///
/// Results are deduplicated by resulting interaction name and ordered by
/// highest offspring probability where each interaction appears.
final epistasisInteractionsProvider = Provider<List<EpistaticInteraction>>((
  ref,
) {
  final results = ref.watch(offspringResultsProvider);
  if (results == null || results.isEmpty) return const [];

  const epistasis = EpistasisEngine();
  final unique = <String, ({EpistaticInteraction interaction, double prob})>{};

  for (final result in results) {
    if (result.visualMutations.isEmpty) continue;
    final interactions = epistasis.getInteractions(
      result.visualMutations.toSet(),
    );
    for (final interaction in interactions) {
      final existing = unique[interaction.resultName];
      if (existing == null || result.probability > existing.prob) {
        unique[interaction.resultName] = (
          interaction: interaction,
          prob: result.probability,
        );
      }
    }
  }

  final sorted = unique.values.toList()
    ..sort((a, b) => b.prob.compareTo(a.prob));
  return sorted.map((entry) => entry.interaction).toList();
});
