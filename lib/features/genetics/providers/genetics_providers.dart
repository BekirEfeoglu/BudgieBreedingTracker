import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/lethal_combination_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_colors.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/genetic_charts.dart';

/// Father genotype with allele states per mutation.
class FatherGenotypeNotifier extends Notifier<ParentGenotype> {
  @override
  ParentGenotype build() => const ParentGenotype.empty(gender: BirdGender.male);
}

final fatherGenotypeProvider =
    NotifierProvider<FatherGenotypeNotifier, ParentGenotype>(
      FatherGenotypeNotifier.new,
    );

/// Mother genotype with allele states per mutation.
class MotherGenotypeNotifier extends Notifier<ParentGenotype> {
  @override
  ParentGenotype build() =>
      const ParentGenotype.empty(gender: BirdGender.female);
}

final motherGenotypeProvider =
    NotifierProvider<MotherGenotypeNotifier, ParentGenotype>(
      MotherGenotypeNotifier.new,
    );

/// Selected father bird name (for UI feedback after bird picker).
class SelectedFatherBirdNameNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

final selectedFatherBirdNameProvider =
    NotifierProvider<SelectedFatherBirdNameNotifier, String?>(
      SelectedFatherBirdNameNotifier.new,
    );

/// Selected mother bird name (for UI feedback after bird picker).
class SelectedMotherBirdNameNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

final selectedMotherBirdNameProvider =
    NotifierProvider<SelectedMotherBirdNameNotifier, String?>(
      SelectedMotherBirdNameNotifier.new,
    );

/// Parent visual mutation IDs used by viability checks.
final fatherMutationsProvider = Provider<Set<String>>((ref) {
  final father = ref.watch(fatherGenotypeProvider);
  return _extractVisualMutationIds(father);
});

/// Parent visual mutation IDs used by viability checks.
final motherMutationsProvider = Provider<Set<String>>((ref) {
  final mother = ref.watch(motherGenotypeProvider);
  return _extractVisualMutationIds(mother);
});

/// Whether to show sex-specific offspring results.
class ShowSexSpecificNotifier extends Notifier<bool> {
  @override
  bool build() => true;
}

final showSexSpecificProvider = NotifierProvider<ShowSexSpecificNotifier, bool>(
  ShowSexSpecificNotifier.new,
);

/// Whether to show genotype details on result cards.
class ShowGenotypeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

final showGenotypeProvider = NotifierProvider<ShowGenotypeNotifier, bool>(
  ShowGenotypeNotifier.new,
);

/// Current wizard step (0=parents, 1=preview, 2=results).
class WizardStepNotifier extends Notifier<int> {
  @override
  int build() => 0;
}

final wizardStepProvider = NotifierProvider<WizardStepNotifier, int>(
  WizardStepNotifier.new,
);

/// Singleton instance of the Mendelian calculator.
final mendelianCalculatorProvider = Provider<MendelianCalculator>((ref) {
  return const MendelianCalculator();
});

/// Calculated offspring results from current genotype selections.
final offspringResultsProvider = Provider<List<OffspringResult>?>((ref) {
  final father = ref.watch(fatherGenotypeProvider);
  final mother = ref.watch(motherGenotypeProvider);

  if (father.isEmpty && mother.isEmpty) return null;

  final calculator = ref.watch(mendelianCalculatorProvider);

  return calculator.calculateFromGenotypes(father: father, mother: mother);
});

/// Selected mutation ID for Punnett square display.
class SelectedPunnettLocusNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

final selectedPunnettLocusProvider =
    NotifierProvider<SelectedPunnettLocusNotifier, String?>(
      SelectedPunnettLocusNotifier.new,
    );

/// List of loci available for Punnett square selection.
///
/// For allelic series mutations, the locusId is used (e.g., 'dilution')
/// instead of individual mutation IDs. Independent mutations use their own ID.
final availablePunnettLociProvider = Provider<List<String>>((ref) {
  final father = ref.watch(fatherGenotypeProvider);
  final mother = ref.watch(motherGenotypeProvider);
  final allIds = {...father.allMutationIds, ...mother.allMutationIds};

  final loci = <String>{};
  for (final id in allIds) {
    final record = MutationDatabase.getById(id);
    if (record?.locusId != null) {
      loci.add(record!.locusId!);
    } else {
      loci.add(id);
    }
  }

  final ordered = loci.toList()
    ..sort((a, b) {
      final keyA = _punnettLocusSortKey(a);
      final keyB = _punnettLocusSortKey(b);
      final byKey = keyA.compareTo(keyB);
      if (byKey != 0) return byKey;
      return a.compareTo(b);
    });
  return ordered;
});

/// Selected locus normalized against currently available loci.
///
/// If the previously selected locus disappears after genotype edits, this
/// provider falls back to the first available locus to keep the Punnett square
/// visible and avoid stale selection state.
final effectivePunnettLocusProvider = Provider<String?>((ref) {
  final availableLoci = ref.watch(availablePunnettLociProvider);
  if (availableLoci.isEmpty) return null;

  final selectedLocus = ref.watch(selectedPunnettLocusProvider);
  if (selectedLocus != null && availableLoci.contains(selectedLocus)) {
    return selectedLocus;
  }

  return availableLoci.first;
});

/// Punnett square data for current selections.
final punnettSquareProvider = Provider<PunnettSquareData?>((ref) {
  final father = ref.watch(fatherGenotypeProvider);
  final mother = ref.watch(motherGenotypeProvider);

  if (father.isEmpty && mother.isEmpty) return null;

  final selectedLocus = ref.watch(effectivePunnettLocusProvider);
  if (selectedLocus == null) return null;
  final calculator = ref.watch(mendelianCalculatorProvider);

  return calculator.buildPunnettSquareFromGenotypes(
    father: father,
    mother: mother,
    mutationId: selectedLocus,
  );
});

/// Optional second locus for dihybrid Punnett square.
class SelectedPunnettLocus2Notifier extends Notifier<String?> {
  @override
  String? build() => null;
}

final selectedPunnettLocus2Provider =
    NotifierProvider<SelectedPunnettLocus2Notifier, String?>(
      SelectedPunnettLocus2Notifier.new,
    );

/// Dihybrid (4×4) Punnett square for two selected loci.
///
/// Returns null when fewer than 2 distinct loci are selected or available.
final dihybridPunnettSquareProvider = Provider<PunnettSquareData?>((ref) {
  final father = ref.watch(fatherGenotypeProvider);
  final mother = ref.watch(motherGenotypeProvider);

  if (father.isEmpty && mother.isEmpty) return null;

  final locus1 = ref.watch(effectivePunnettLocusProvider);
  final locus2 = ref.watch(selectedPunnettLocus2Provider);

  if (locus1 == null || locus2 == null || locus1 == locus2) return null;

  final availableLoci = ref.watch(availablePunnettLociProvider);
  if (!availableLoci.contains(locus2)) return null;

  final calculator = ref.watch(mendelianCalculatorProvider);
  return calculator.buildDihybridPunnettSquare(
    father: father,
    mother: mother,
    locusId1: locus1,
    locusId2: locus2,
  );
});

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

const _punnettLocusDisplayName = <String, String>{
  'blue_series': 'Blue Series',
  'dilution': 'Dilution',
  'crested': 'Crested',
  'ino_locus': 'Ino Locus',
};

String _punnettLocusSortKey(String locusId) {
  final record = MutationDatabase.getById(locusId);
  if (record != null) {
    return record.name.toLowerCase();
  }

  final knownLocusName = _punnettLocusDisplayName[locusId];
  if (knownLocusName != null) {
    return knownLocusName.toLowerCase();
  }

  return locusId.toLowerCase();
}

Set<String> _extractVisualMutationIds(ParentGenotype genotype) {
  final visualIds = <String>{};
  for (final entry in genotype.mutations.entries) {
    final mutationId = entry.key;
    final alleleState = entry.value;
    final mutation = MutationDatabase.getById(mutationId);
    if (mutation == null) continue;

    final isVisual = switch (mutation.inheritanceType) {
      InheritanceType.autosomalRecessive => alleleState == AlleleState.visual,
      InheritanceType.autosomalDominant ||
      InheritanceType.autosomalIncompleteDominant =>
        alleleState == AlleleState.visual ||
            alleleState == AlleleState.carrier ||
            alleleState == AlleleState.split,
      InheritanceType.sexLinkedRecessive ||
      InheritanceType.sexLinkedCodominant =>
        genotype.gender == BirdGender.female
            ? true
            : alleleState == AlleleState.visual,
    };

    if (isVisual) {
      visualIds.add(mutationId);
    }
  }
  return visualIds;
}
