import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/linkage_phase.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';

/// Verifies that [ParentGenotype.phaseOverrides] survives the `compute()`
/// isolate boundary in [offspringCalculationProvider]. The isolate entry
/// point (`_calculateDetailedInIsolate`) is library-private, so this exercises
/// the real provider chain end-to-end rather than calling it directly.
///
/// `OffspringResult` has no value `==`, so comparing raw lists would always
/// report "different" (reference identity) regardless of whether the phase
/// actually crossed the isolate boundary. [_summarize] projects each result
/// to a `(phenotype, probability)` record — which Dart records compare
/// structurally — so equality reflects the real computed distribution.
List<(String, double)> _summarize(List<OffspringResult>? results) {
  final list = (results ?? const <OffspringResult>[])
      .map((r) => (r.phenotype, double.parse(r.probability.toStringAsFixed(6))))
      .toList()
    ..sort((a, b) => a.$1.compareTo(b.$1));
  return list;
}

ParentGenotype _fatherSplitBoth() => ParentGenotype(
  gender: BirdGender.male,
  mutations: {'ino': AlleleState.split, 'cinnamon': AlleleState.split},
);

Future<List<OffspringResult>?> _resultsFor(ParentGenotype father) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(fatherGenotypeProvider.notifier).state = father;
  container.read(motherGenotypeProvider.notifier).state =
      const ParentGenotype.empty(gender: BirdGender.female);
  return container.read(offspringResultsProvider.future);
}

void main() {
  group('offspringCalculationProvider — linkage phase override round-trip', () {
    test(
      'coupling override changes offspring distribution vs auto (both split)',
      () async {
        // Father heterozygous (split) at both ino and cinnamon — a real
        // Z-linked pair (~3 cM). Auto-inference treats double-split as
        // repulsion; an explicit coupling override should diverge from that.
        final autoResults = await _resultsFor(_fatherSplitBoth());
        final overrideResults = await _resultsFor(
          _fatherSplitBoth().withPhaseOverride(
            'ino',
            'cinnamon',
            LinkagePhase.coupling,
          ),
        );

        expect(autoResults, isNotNull);
        expect(overrideResults, isNotNull);
        // The override must have crossed the isolate boundary and altered the
        // computed offspring distribution — otherwise it was silently dropped
        // during serialization and both would resolve to the same (auto =
        // repulsion) distribution.
        expect(_summarize(overrideResults), isNot(equals(_summarize(autoResults))));
      },
    );

    test(
      'repulsion override matches the auto (both split) distribution — a '
      'control case confirming the pipeline still produces a valid result '
      'when the override happens to agree with the inferred phase',
      () async {
        final autoResults = await _resultsFor(_fatherSplitBoth());
        final overrideResults = await _resultsFor(
          _fatherSplitBoth().withPhaseOverride(
            'ino',
            'cinnamon',
            LinkagePhase.repulsion,
          ),
        );

        expect(_summarize(overrideResults), equals(_summarize(autoResults)));
      },
    );
  });
}
