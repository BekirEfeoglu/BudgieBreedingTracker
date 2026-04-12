part of 'mendelian_calculator.dart';

// ---------------------------------------------------------------------------
// Step 3: Normalize probabilities and sort
// ---------------------------------------------------------------------------

/// Normalizes offspring result probabilities to sum to 1.0, filters entries
/// below 0.1% threshold, and sorts by descending probability.
List<OffspringResult> _normalizeAndSort(
  Map<String, OffspringResult> resultMap,
) {
  final total = resultMap.values.fold(0.0, (sum, r) => sum + r.probability);
  final normalizer = total > 0 ? 1.0 / total : 1.0;

  final sorted = resultMap.values.toList()
    ..sort((a, b) => b.probability.compareTo(a.probability));

  return sorted
      .where((r) => r.probability * normalizer > GeneticsConstants.probabilityMinThreshold)
      .map(
        (r) => OffspringResult(
          phenotype: r.phenotype,
          probability: r.probability * normalizer,
          sex: r.sex,
          isCarrier: r.isCarrier,
          genotype: r.genotype,
          visualMutations: r.visualMutations,
          compoundPhenotype: r.compoundPhenotype,
          carriedMutations: r.carriedMutations,
          maskedMutations: r.maskedMutations,
          doubleFactorIds: r.doubleFactorIds,
        ),
      )
      .toList();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Converts a phenotype display name to its mutation ID.
/// Falls back to [name] when no matching record is found.
String _nameToId(String name) => MutationDatabase.getByName(name)?.id ?? name;

bool _sexCompatible(OffspringSex a, OffspringSex b) {
  if (a == OffspringSex.both || b == OffspringSex.both) return true;
  return a == b;
}

OffspringSex _mergeSex(OffspringSex a, OffspringSex b) {
  if (a == b) return a;
  if (a == OffspringSex.both) return b;
  if (b == OffspringSex.both) return a;
  return a; // Should not happen if _sexCompatible passed
}

/// Extracts visual mutation IDs and double-factor flags from a combined
/// multi-locus result, using expressed IDs and falling back to name→ID lookup.
({Set<String> visualMutIds, Set<String> doubleFactorIds}) _extractMutationIds(
  _MultiLocusResult c,
) {
  // Separate visual phenotype names from carrier info
  final visualNames = c.phenotypes
      .where((p) => !p.contains('(carrier)'))
      .toList();

  // Prefer expressedMutationIds from allelic series results
  final visualMutIds = <String>{...c.expressedMutationIds};
  final doubleFactorIds = <String>{};

  // Fallback: name→ID lookup for legacy independent locus results
  for (final name in visualNames) {
    final cleanName = name
        .replaceAll(' (single)', '')
        .replaceAll(' (double)', '')
        .replaceAll(' (homozygous)', '');
    final id = MutationDatabase.getByName(cleanName)?.id;
    if (id != null) {
      visualMutIds.add(id);
      if (name.contains('(double)')) {
        doubleFactorIds.add(id);
      }
    }
  }

  return (visualMutIds: visualMutIds, doubleFactorIds: doubleFactorIds);
}

/// Builds a phenotype label from compound name and carried mutations.
String _buildPhenotypeLabel(String compoundName, List<String> uniqueCarried) {
  return uniqueCarried.isNotEmpty
      ? '$compoundName (${uniqueCarried.join(", ")} carrier)'
      : compoundName;
}
