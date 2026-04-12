part of 'genetics_providers.dart';

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
