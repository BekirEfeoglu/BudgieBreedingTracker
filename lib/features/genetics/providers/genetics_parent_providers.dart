part of 'genetics_providers.dart';

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

/// Identity of a bird chosen from the user's collection to seed a parent.
/// Carrying the id (not just the name) lets a saved calculation round-trip back
/// to the real bird record via [GeneticsHistory.fatherBirdId]/`motherBirdId`.
typedef SelectedParentBird = ({String id, String name});

/// Provenance of a parent genotype:
/// - [manual]: typed in by hand.
/// - [fromBird]: seeded from a selected bird, unchanged.
/// - [fromBirdEdited]: seeded from a bird, then hand-edited by the user.
enum ParentGenotypeSource { manual, fromBird, fromBirdEdited }

/// Selected father bird identity (id + name) after the bird picker.
class SelectedFatherBirdNotifier extends Notifier<SelectedParentBird?> {
  @override
  SelectedParentBird? build() => null;
}

final selectedFatherBirdProvider =
    NotifierProvider<SelectedFatherBirdNotifier, SelectedParentBird?>(
      SelectedFatherBirdNotifier.new,
    );

/// Selected mother bird identity (id + name) after the bird picker.
class SelectedMotherBirdNotifier extends Notifier<SelectedParentBird?> {
  @override
  SelectedParentBird? build() => null;
}

final selectedMotherBirdProvider =
    NotifierProvider<SelectedMotherBirdNotifier, SelectedParentBird?>(
      SelectedMotherBirdNotifier.new,
    );

/// Provenance of the father genotype (drives the "from bird / edited" badge).
class FatherGenotypeSourceNotifier extends Notifier<ParentGenotypeSource> {
  @override
  ParentGenotypeSource build() => ParentGenotypeSource.manual;
}

final fatherGenotypeSourceProvider =
    NotifierProvider<FatherGenotypeSourceNotifier, ParentGenotypeSource>(
      FatherGenotypeSourceNotifier.new,
    );

/// Provenance of the mother genotype.
class MotherGenotypeSourceNotifier extends Notifier<ParentGenotypeSource> {
  @override
  ParentGenotypeSource build() => ParentGenotypeSource.manual;
}

final motherGenotypeSourceProvider =
    NotifierProvider<MotherGenotypeSourceNotifier, ParentGenotypeSource>(
      MotherGenotypeSourceNotifier.new,
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

/// Filter for offspring results.
enum OffspringFilter { all, carrierOnly, visualOnly }

/// Active offspring result filter.
class OffspringFilterNotifier extends Notifier<OffspringFilter> {
  @override
  OffspringFilter build() => OffspringFilter.all;
}

final offspringFilterProvider =
    NotifierProvider<OffspringFilterNotifier, OffspringFilter>(
      OffspringFilterNotifier.new,
    );

/// Current wizard step (0=parents, 1=preview, 2=results).
class WizardStepNotifier extends Notifier<int> {
  @override
  int build() => 0;
}

final wizardStepProvider = NotifierProvider<WizardStepNotifier, int>(
  WizardStepNotifier.new,
);
