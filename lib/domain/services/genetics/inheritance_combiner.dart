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
        doubleFactorIds: {...existing.doubleFactorIds, ...r.doubleFactorIds},
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

  return sorted
      .where(
        (r) =>
            r.probability * normalizer >
            GeneticsConstants.probabilityMinThreshold,
      )
      .map((r) {
    final visualIds = r.expressedMutationIds.toSet();

    // Derive doubleFactorIds from structural allelic-series tagging plus the
    // legacy phenotype-string markers for independent-locus results.
    final dfIds = <String>{...r.doubleFactorIds};
    if (r.phenotype.contains('(double)') ||
        r.phenotype.contains('(homozygous)')) {
      dfIds.addAll(r.expressedMutationIds);
    }

    final CompoundPhenotypeResult? compound = visualIds.isNotEmpty
        ? epistasis.resolveCompoundPhenotypeDetailed(
            visualIds,
            doubleFactorIds: dfIds,
          )
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
      doubleFactorIds: dfIds,
    );
  }).toList();
}

/// Combines results across multiple independent loci by multiplying
/// probabilities and merging phenotype names, returning the offspring list plus
/// [PruningDiagnostics] describing any combinatorial pruning that occurred.
({List<OffspringResult> results, PruningDiagnostics diagnostics})
_combineMultiLocus(Map<String, List<_RawResult>> perLocusResults) {
  final crossed = _crossAllLoci(perLocusResults);
  final resultMap = _resolveEpistasisForCombined(crossed.results);
  final results = _normalizeAndSort(resultMap);
  return (
    results: results,
    diagnostics: PruningDiagnostics(
      wasPruned: crossed.prunedStateCount > 0,
      prunedStateCount: crossed.prunedStateCount,
      discardedProbabilityMassBeforeNormalization: crossed.discardedMass,
      normalized: results.isNotEmpty,
    ),
  );
}

// ---------------------------------------------------------------------------
// Step 1: Cross all loci (Cartesian product with probability multiplication)
// ---------------------------------------------------------------------------

/// Builds the Cartesian product of per-locus results, multiplying
/// probabilities across loci and merging phenotype/genotype metadata.
({List<_MultiLocusResult> results, int prunedStateCount, double discardedMass})
_crossAllLoci(Map<String, List<_RawResult>> perLocusResults) {
  var prunedStateCount = 0;
  var discardedMass = 0.0;
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
          doubleFactorIds: {...r.doubleFactorIds},
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
            doubleFactorIds: {
              ...existing.doubleFactorIds,
              ...locusResult.doubleFactorIds,
            },
          ),
        );
      }
    }

    combined = newCombined;

    // Early pruning: discard very low probability entries to prevent
    // combinatorial explosion when many loci are selected. Track what is
    // dropped (count + raw mass) so callers can surface a coverage warning.
    final kept = <_MultiLocusResult>[];
    for (final c in combined) {
      if (c.probability >= GeneticsConstants.probabilityPruningThreshold) {
        kept.add(c);
      } else {
        prunedStateCount++;
        discardedMass += c.probability;
      }
    }
    combined = kept;
  }

  return (
    results: combined,
    prunedStateCount: prunedStateCount,
    discardedMass: discardedMass,
  );
}

// ---------------------------------------------------------------------------
// Step 2: Resolve epistasis and build OffspringResult map
// ---------------------------------------------------------------------------

/// Resolves epistasis for each combined multi-locus result and groups
/// identical phenotypes into an [OffspringResult] map.
Map<String, OffspringResult> _resolveEpistasisForCombined(
  List<_MultiLocusResult> combined,
) {
  const epistasis = EpistasisEngine();
  final resultMap = <String, OffspringResult>{};

  for (final c in combined) {
    if (c.probability < GeneticsConstants.probabilityMinThreshold) continue;

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
    final baseLabel = _buildPhenotypeLabel(compoundName, uniqueCarried);

    // Keep the double-factor subset as its own result (it carries the
    // semi-lethal/lethal warning and its own ~25% probability) instead of
    // collapsing it into the single-factor phenotype group. The epistasis
    // compound name is identical for homozygous vs heterozygous dominant, so
    // without a distinct label they merged into one key and the doubleFactorIds
    // tag was overwritten/lost — dropping every offspringHomozygous lethal
    // (crested, DF spangle, feather duster, DF dominant pied) in multi-locus
    // crosses. Mirrors the single-locus path, which labels the DF result
    // separately ("(double)"/"(homozygous)").
    final phenotypeLabel = doubleFactorIds.isEmpty
        ? baseLabel
        : '$baseLabel (double factor)';

    // Include the EXACT double-factor set in the grouping key so results whose
    // homozygous loci differ don't merge — merging would union their DF tags
    // and over-attribute a lethal to offspring that aren't actually homozygous
    // for it (e.g. an Aa dominant-pied × bb blue group being tagged
    // dominant_pied because it shares the base label with the AA×bb group).
    // The visual/masked sets are part of the result's identity, not just
    // decoration. The epistasis compound name is built AFTER masking, so two
    // genotypically different states can share one label — e.g. under a visual
    // ino cross, a heterozygous dominant Blackface (masked: [blackface]) and
    // the plain wild-type (masked: []) both resolve to "Lutino" with an empty
    // DF set and no carried mutations. Keying on the label alone collapsed them
    // and the merge branch then OVERWROTE visualMutations/maskedMutations with
    // whichever state iterated last, so the persisted hidden-gene readout was
    // wrong for part of the group. Key on the full identity and union on merge.
    final identity =
        '${(visualMutIds.toList()..sort()).join(",")}'
        '/${(maskedMuts.toList()..sort()).join(",")}';
    final key = doubleFactorIds.isEmpty
        ? '$phenotypeLabel|${c.sex.name}|$identity'
        : '$phenotypeLabel|${c.sex.name}|$identity'
              '|${(doubleFactorIds.toList()..sort()).join(",")}';

    if (resultMap.containsKey(key)) {
      final existing = resultMap[key]!;
      resultMap[key] = OffspringResult(
        phenotype: phenotypeLabel,
        probability: existing.probability + c.probability,
        sex: c.sex,
        isCarrier: uniqueCarried.isNotEmpty,
        genotype: existing.genotype,
        visualMutations: {
          ...existing.visualMutations,
          ...visualMutIds,
        }.toList(),
        compoundPhenotype: compoundName,
        carriedMutations: {
          ...existing.carriedMutations,
          ...uniqueCarried,
        }.toList(),
        maskedMutations: {...existing.maskedMutations, ...maskedMuts}.toList(),
        doubleFactorIds: {...existing.doubleFactorIds, ...doubleFactorIds},
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
        doubleFactorIds: doubleFactorIds,
      );
    }
  }

  return resultMap;
}
