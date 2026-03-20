part of 'genetics_providers.dart';

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
