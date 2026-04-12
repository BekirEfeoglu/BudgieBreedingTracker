part of 'genetics_providers.dart';

const _locusSortOrder = <String, int>{
  GeneticsConstants.locusBlueSeries: 0,
  GeneticsConstants.locusDilution: 1,
  GeneticsConstants.locusCrested: 2,
  GeneticsConstants.locusIno: 3,
};

String _punnettLocusSortKey(String locusId) {
  final sortIndex = _locusSortOrder[locusId];
  if (sortIndex != null) return sortIndex.toString().padLeft(2, '0');
  final record = MutationDatabase.getById(locusId);
  return record?.name.toLowerCase() ?? locusId.toLowerCase();
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
