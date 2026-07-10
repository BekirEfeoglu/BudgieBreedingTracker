import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

/// Q1 — pruning diagnostics. Verifies `calculateDetailed` reports the early
/// combinatorial pruning honestly while `calculateFromGenotypes` keeps its
/// exact previous output.
void main() {
  const calculator = MendelianCalculator();

  ParentGenotype carriers(BirdGender gender, List<String> ids) => ParentGenotype(
        gender: gender,
        mutations: {for (final id in ids) id: AlleleState.carrier},
      );

  String sig(OffspringResult r) =>
      '${r.phenotype}|${r.sex.name}|${r.probability}';

  group('PruningDiagnostics — no pruning', () {
    test('single-locus cross reports no pruning (still normalized)', () {
      final detailed = calculator.calculateDetailed(
        father: ParentGenotype(
          gender: BirdGender.male,
          mutations: const {'blue': AlleleState.carrier},
        ),
        mother: ParentGenotype(
          gender: BirdGender.female,
          mutations: const {'blue': AlleleState.carrier},
        ),
      );
      expect(detailed.diagnostics.wasPruned, isFalse);
      expect(detailed.diagnostics.prunedStateCount, 0);
      expect(
        detailed.diagnostics.discardedProbabilityMassBeforeNormalization,
        0.0,
      );
      expect(detailed.diagnostics.normalized, isTrue);
    });

    test('5 independent loci stay under the pruning threshold', () {
      final ids = ['blue', 'grey', 'violet', 'dark_factor', 'spangle'];
      final detailed = calculator.calculateDetailed(
        father: carriers(BirdGender.male, ids),
        mother: carriers(BirdGender.female, ids),
      );
      expect(detailed.diagnostics.wasPruned, isFalse);
      expect(detailed.diagnostics.prunedStateCount, 0);
      expect(detailed.results, isNotEmpty);
    });

    test('empty cross returns the empty calculation', () {
      final detailed = calculator.calculateDetailed(
        father: const ParentGenotype.empty(gender: BirdGender.male),
        mother: const ParentGenotype.empty(gender: BirdGender.female),
      );
      expect(detailed.results, isEmpty);
      expect(detailed.diagnostics.wasPruned, isFalse);
      expect(detailed.diagnostics.normalized, isFalse);
    });
  });

  group('PruningDiagnostics — pruning occurs', () {
    test('6 independent loci prune states and discard measurable mass', () {
      final ids = [
        'blue',
        'grey',
        'violet',
        'dark_factor',
        'spangle',
        'anthracite',
      ];
      final detailed = calculator.calculateDetailed(
        father: carriers(BirdGender.male, ids),
        mother: carriers(BirdGender.female, ids),
      );
      expect(detailed.diagnostics.wasPruned, isTrue);
      expect(detailed.diagnostics.prunedStateCount, greaterThan(0));
      // Deterministic for a fixed engine version: ~10.9% of the joint mass.
      expect(
        detailed.diagnostics.discardedProbabilityMassBeforeNormalization,
        closeTo(0.109, 0.02),
      );
      // Reported mass is a raw pre-normalization fraction (0..1).
      expect(
        detailed.diagnostics.discardedProbabilityMassBeforeNormalization,
        inInclusiveRange(0.0, 1.0),
      );
      expect(detailed.diagnostics.normalized, isTrue);
    });

    test('7 loci prune heavily (~50% of the mass)', () {
      final ids = [
        'blue',
        'grey',
        'violet',
        'dark_factor',
        'spangle',
        'anthracite',
        'greywing',
      ];
      final detailed = calculator.calculateDetailed(
        father: carriers(BirdGender.male, ids),
        mother: carriers(BirdGender.female, ids),
      );
      expect(detailed.diagnostics.wasPruned, isTrue);
      expect(
        detailed.diagnostics.discardedProbabilityMassBeforeNormalization,
        closeTo(0.5, 0.05),
      );
    });

    test('diagnostics expose the applied thresholds', () {
      final ids = [
        'blue',
        'grey',
        'violet',
        'dark_factor',
        'spangle',
        'anthracite',
      ];
      final d = calculator
          .calculateDetailed(
            father: carriers(BirdGender.male, ids),
            mother: carriers(BirdGender.female, ids),
          )
          .diagnostics;
      expect(d.earlyPruningThreshold,
          GeneticsConstants.probabilityPruningThreshold);
      expect(d.minResultThreshold, GeneticsConstants.probabilityMinThreshold);
    });

    test('deterministic: same input yields the same diagnostics', () {
      final ids = [
        'blue',
        'grey',
        'violet',
        'dark_factor',
        'spangle',
        'anthracite',
      ];
      final a = calculator
          .calculateDetailed(
            father: carriers(BirdGender.male, ids),
            mother: carriers(BirdGender.female, ids),
          )
          .diagnostics;
      final b = calculator
          .calculateDetailed(
            father: carriers(BirdGender.male, ids),
            mother: carriers(BirdGender.female, ids),
          )
          .diagnostics;
      expect(a.prunedStateCount, b.prunedStateCount);
      expect(
        a.discardedProbabilityMassBeforeNormalization,
        b.discardedProbabilityMassBeforeNormalization,
      );
    });
  });

  group('calculateFromGenotypes byte-semantics preserved', () {
    test('list output is identical to calculateDetailed(...).results', () {
      for (final ids in [
        ['blue'],
        ['cinnamon', 'ino'],
        ['blue', 'grey', 'violet', 'dark_factor', 'spangle', 'anthracite'],
      ]) {
        final father = carriers(BirdGender.male, ids);
        final mother = carriers(BirdGender.female, ids);
        final plain = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );
        final detailed = calculator.calculateDetailed(
          father: father,
          mother: mother,
        );
        expect(
          plain.map(sig).toList(),
          detailed.results.map(sig).toList(),
          reason: 'output must stay identical for ${ids.length} loci',
        );
      }
    });
  });
}
