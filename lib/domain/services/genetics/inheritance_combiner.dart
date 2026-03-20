part of 'mendelian_calculator.dart';

// ---------------------------------------------------------------------------
// Result combination
// ---------------------------------------------------------------------------

/// Combines raw results, merging duplicate phenotypes.
///
/// Also resolves compound phenotype names via [EpistasisEngine] so that
/// even single-locus results get correct epistatic naming (e.g., Ino alone
/// on green series → "Lutino").
List<OffspringResult> _combineResults(List<_RawResult> rawResults) {
  if (rawResults.isEmpty) return [];

  // Group by (phenotype, sex) key
  final grouped = <String, _RawResult>{};

  for (final r in rawResults) {
    final key = '${r.phenotype}|${r.sex.name}';
    if (grouped.containsKey(key)) {
      final existing = grouped[key]!;
      grouped[key] = _RawResult(
        phenotype: r.phenotype,
        probability: existing.probability + r.probability,
        sex: r.sex,
        isCarrier: r.isCarrier || existing.isCarrier,
        genotype: r.genotype ?? existing.genotype,
        expressedMutationIds: {
          ...existing.expressedMutationIds,
          ...r.expressedMutationIds,
        }.toList(),
        carriedMutationIds: {
          ...existing.carriedMutationIds,
          ...r.carriedMutationIds,
        }.toList(),
      );
    } else {
      grouped[key] = r;
    }
  }

  // Normalize probabilities so they sum to 1.0
  final total = grouped.values.fold(0.0, (sum, r) => sum + r.probability);
  final normalizer = total > 0 ? 1.0 / total : 1.0;

  final sorted = grouped.values.toList()
    ..sort((a, b) => b.probability.compareTo(a.probability));

  // Resolve compound phenotype names via EpistasisEngine
  const epistasis = EpistasisEngine();

  return sorted.where((r) => r.probability * normalizer > 0.001).map((r) {
    final visualIds = r.expressedMutationIds.toSet();
    final CompoundPhenotypeResult? compound = visualIds.isNotEmpty
        ? epistasis.resolveCompoundPhenotypeDetailed(visualIds)
        : null;

    return OffspringResult(
      phenotype: r.phenotype,
      probability: r.probability * normalizer,
      sex: r.sex,
      isCarrier: r.isCarrier,
      genotype: r.genotype,
      visualMutations: r.expressedMutationIds,
      compoundPhenotype: compound?.name,
      carriedMutations: r.carriedMutationIds,
      maskedMutations: compound?.maskedMutations ?? const [],
    );
  }).toList();
}

/// Combines results across multiple independent loci by multiplying
/// probabilities and merging phenotype names.
List<OffspringResult> _combineMultiLocus(
  Map<String, List<_RawResult>> perLocusResults,
) {
  final combined = _crossAllLoci(perLocusResults);
  final resultMap = _resolveEpistasisForCombined(combined);
  return _normalizeAndSort(resultMap);
}

// ---------------------------------------------------------------------------
// Step 1: Cross all loci (Cartesian product with probability multiplication)
// ---------------------------------------------------------------------------

/// Builds the Cartesian product of per-locus results, multiplying
/// probabilities across loci and merging phenotype/genotype metadata.
List<_MultiLocusResult> _crossAllLoci(
  Map<String, List<_RawResult>> perLocusResults,
) {
  final loci = perLocusResults.keys.toList();
  var combined = perLocusResults[loci[0]]!
      .map(
        (r) => _MultiLocusResult(
          phenotypes: r.phenotype == 'Normal' ? [] : [r.phenotype],
          probability: r.probability,
          sex: r.sex,
          carriedMutations: [
            if (r.isCarrier && r.carriedMutationIds.isEmpty)
              _nameToId(r.phenotype.replaceAll(' (carrier)', '')),
            ...r.carriedMutationIds,
          ],
          genotypes: r.genotype != null ? [r.genotype!] : [],
          expressedMutationIds: [...r.expressedMutationIds],
        ),
      )
      .toList();

  // Cross with each subsequent locus
  for (var i = 1; i < loci.length; i++) {
    final locusResults = perLocusResults[loci[i]]!;
    final newCombined = <_MultiLocusResult>[];

    for (final existing in combined) {
      for (final locusResult in locusResults) {
        // Check sex compatibility
        if (!_sexCompatible(existing.sex, locusResult.sex)) continue;

        final mergedSex = _mergeSex(existing.sex, locusResult.sex);

        final phenotypes = [...existing.phenotypes];
        if (locusResult.phenotype != 'Normal') {
          phenotypes.add(locusResult.phenotype);
        }

        final carried = [...existing.carriedMutations];
        if (locusResult.isCarrier && locusResult.carriedMutationIds.isEmpty) {
          carried.add(
            _nameToId(locusResult.phenotype.replaceAll(' (carrier)', '')),
          );
        }
        carried.addAll(locusResult.carriedMutationIds);

        final genotypes = [...existing.genotypes];
        if (locusResult.genotype != null) {
          genotypes.add(locusResult.genotype!);
        }

        final expressedIds = [
          ...existing.expressedMutationIds,
          ...locusResult.expressedMutationIds,
        ];

        newCombined.add(
          _MultiLocusResult(
            phenotypes: phenotypes,
            probability: existing.probability * locusResult.probability,
            sex: mergedSex,
            carriedMutations: carried,
            genotypes: genotypes,
            expressedMutationIds: expressedIds,
          ),
        );
      }
    }

    combined = newCombined;

    // Early pruning: discard very low probability entries to prevent
    // combinatorial explosion when many loci are selected.
    combined = combined.where((c) => c.probability >= 0.0005).toList();
  }

  return combined;
}

// ---------------------------------------------------------------------------
// Step 2: Resolve epistasis and build OffspringResult map
// ---------------------------------------------------------------------------

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

/// Resolves epistasis for each combined multi-locus result and groups
/// identical phenotypes into an [OffspringResult] map.
Map<String, OffspringResult> _resolveEpistasisForCombined(
  List<_MultiLocusResult> combined,
) {
  const epistasis = EpistasisEngine();
  final resultMap = <String, OffspringResult>{};

  for (final c in combined) {
    if (c.probability < 0.001) continue;

    final (:visualMutIds, :doubleFactorIds) = _extractMutationIds(c);

    // Resolve compound phenotype via epistasis engine (with masked mutations)
    final CompoundPhenotypeResult compoundResult;
    if (visualMutIds.isNotEmpty) {
      compoundResult = epistasis.resolveCompoundPhenotypeDetailed(
        visualMutIds,
        doubleFactorIds: doubleFactorIds,
      );
    } else {
      compoundResult = const CompoundPhenotypeResult(name: 'Normal');
    }
    final compoundName = compoundResult.name;
    final maskedMuts = compoundResult.maskedMutations;

    final carrierNames = c.phenotypes
        .where((p) => p.contains('(carrier)'))
        .map((p) => p.replaceAll(' (carrier)', ''))
        .toList();
    // Normalize phenotype names to mutation IDs for consistent deduplication
    final carrierIds = carrierNames.map((name) {
      return MutationDatabase.getByName(name)?.id ?? name;
    }).toList();
    final allCarried = [...carrierIds, ...c.carriedMutations];
    final uniqueCarried = allCarried.toSet().toList();
    final phenotypeLabel = _buildPhenotypeLabel(compoundName, uniqueCarried);

    final key = '$phenotypeLabel|${c.sex.name}';

    if (resultMap.containsKey(key)) {
      final existing = resultMap[key]!;
      resultMap[key] = OffspringResult(
        phenotype: phenotypeLabel,
        probability: existing.probability + c.probability,
        sex: c.sex,
        isCarrier: uniqueCarried.isNotEmpty,
        genotype: existing.genotype,
        visualMutations: visualMutIds.toList(),
        compoundPhenotype: compoundName,
        carriedMutations: {
          ...existing.carriedMutations,
          ...uniqueCarried,
        }.toList(),
        maskedMutations: maskedMuts,
      );
    } else {
      resultMap[key] = OffspringResult(
        phenotype: phenotypeLabel,
        probability: c.probability,
        sex: c.sex,
        isCarrier: uniqueCarried.isNotEmpty,
        genotype: c.genotypes.isNotEmpty ? c.genotypes.join(' | ') : null,
        visualMutations: visualMutIds.toList(),
        compoundPhenotype: compoundName,
        carriedMutations: uniqueCarried,
        maskedMutations: maskedMuts,
      );
    }
  }

  return resultMap;
}

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
      .where((r) => r.probability * normalizer > 0.001)
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
