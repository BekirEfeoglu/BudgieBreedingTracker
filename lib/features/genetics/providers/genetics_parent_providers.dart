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
