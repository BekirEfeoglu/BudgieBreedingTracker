import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/lethal_combination_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

OffspringResult _offspring({
  required String phenotype,
  required double probability,
  OffspringSex sex = OffspringSex.both,
  List<String> visualMutations = const [],
  Set<String> doubleFactorIds = const {},
}) {
  return OffspringResult(
    phenotype: phenotype,
    probability: probability,
    sex: sex,
    visualMutations: visualMutations,
    doubleFactorIds: doubleFactorIds,
  );
}

/// Convenience: a double-factor feather-duster offspring (lethal).
OffspringResult _featherDuster(double p) => _offspring(
      phenotype: 'Feather Duster',
      probability: p,
      doubleFactorIds: {GeneticsConstants.mutFeatherDuster},
    );

/// Convenience: a double-factor crested offspring (sub-vital, v6).
OffspringResult _dfCrested(double p) => _offspring(
      phenotype: 'DF Crested',
      probability: p,
      visualMutations: const ['crested_tufted'],
      doubleFactorIds: const {'crested_tufted', 'crested_half_circular'},
    );

void main() {
  late ViabilityAnalyzer analyzer;

  setUp(() {
    analyzer = const ViabilityAnalyzer();
  });

  group('no warnings', () {
    test('returns empty result for normal parents and normal offspring', () {
      final result = analyzer.analyze(
        fatherMutations: {'blue'},
        motherMutations: {'blue'},
        offspringResults: [
          _offspring(phenotype: 'Blue', probability: 1.0, visualMutations: [
            'blue',
          ]),
        ],
      );

      expect(result.hasWarnings, isFalse);
      expect(result.warnings, isEmpty);
      expect(result.highestSeverity, isNull);
      expect(result.totalAffectedProbability, 0.0);
    });

    test('returns empty result for empty parent mutations', () {
      final result = analyzer.analyze(
        fatherMutations: const {},
        motherMutations: const {},
        offspringResults: [_offspring(phenotype: 'Normal', probability: 1.0)],
      );

      expect(result.hasWarnings, isFalse);
    });
  });

  group('v6 removed the false-positive homozygous-pairing warnings', () {
    test('Ino × Ino is a healthy pairing — no warning', () {
      final result = analyzer.analyze(
        fatherMutations: {'ino'},
        motherMutations: {'ino'},
        offspringResults: [
          _offspring(phenotype: 'Lutino', probability: 0.5),
          _offspring(phenotype: 'Albino', probability: 0.5),
        ],
      );
      expect(result.hasWarnings, isFalse);
    });

    test('Pallid × Pallid and Texas Clearbody × Texas Clearbody — no warning',
        () {
      final pallid = analyzer.analyze(
        fatherMutations: {'pallid'},
        motherMutations: {'pallid'},
        offspringResults: [_offspring(phenotype: 'Pallid', probability: 1.0)],
      );
      final tcb = analyzer.analyze(
        fatherMutations: {'texas_clearbody'},
        motherMutations: {'texas_clearbody'},
        offspringResults: [
          _offspring(phenotype: 'Texas Clearbody', probability: 1.0),
        ],
      );
      expect(pallid.hasWarnings, isFalse);
      expect(tcb.hasWarnings, isFalse);
    });

    test('DF Spangle is viable — no warning', () {
      final result = analyzer.analyze(
        fatherMutations: {'spangle'},
        motherMutations: {'spangle'},
        offspringResults: [
          _offspring(
            phenotype: 'DF Spangle',
            probability: 0.25,
            visualMutations: ['spangle'],
            doubleFactorIds: {'spangle'},
          ),
          _offspring(phenotype: 'Normal', probability: 0.75),
        ],
      );
      expect(result.hasWarnings, isFalse);
    });
  });

  group('offspring-level detection', () {
    test('flags the DF feather-duster offspring as lethal', () {
      final result = analyzer.analyze(
        fatherMutations: {'feather_duster'},
        motherMutations: {'feather_duster'},
        offspringResults: [
          _featherDuster(0.25),
          _offspring(phenotype: 'Normal', probability: 0.75),
        ],
      );

      final warnings = result.warnings.where(
        (w) => w.combination.id == 'df_feather_duster',
      );
      expect(warnings, hasLength(1));
      expect(result.highestSeverity, LethalSeverity.lethal);
    });

    test('flags only the DF crested offspring as sub-vital, not the SF', () {
      final result = analyzer.analyze(
        fatherMutations: {'crested_tufted'},
        motherMutations: {'crested_full_circular'},
        offspringResults: [
          _offspring(
            phenotype: 'DF Crested',
            probability: 0.25,
            visualMutations: ['crested_tufted'],
            doubleFactorIds: {'crested_tufted', 'crested_full_circular'},
          ),
          _offspring(
            phenotype: 'Crested',
            probability: 0.5,
            visualMutations: ['crested_tufted'],
          ),
          _offspring(phenotype: 'Normal', probability: 0.25),
        ],
      );

      final crested = result.warnings.where(
        (w) => w.combination.id == 'df_crested',
      );
      expect(crested, hasLength(1));
      expect(crested.first.offspring.probability, closeTo(0.25, 1e-9));
      expect(result.highestSeverity, LethalSeverity.subVital);
    });

    test('crested does not flag when no offspring is double factor', () {
      final result = analyzer.analyze(
        fatherMutations: {'crested_tufted'},
        motherMutations: {'crested_full_circular'},
        offspringResults: [
          _offspring(
            phenotype: 'Crested',
            probability: 0.5,
            visualMutations: ['crested_tufted'],
          ),
          _offspring(phenotype: 'Normal', probability: 0.5),
        ],
      );
      expect(
        result.warnings.where((w) => w.combination.id == 'df_crested'),
        isEmpty,
      );
    });
  });

  group('recessive lethal with non-visual carrier parents (regression)', () {
    // Feather Duster is autosomal recessive: a carrier parent is NOT visual,
    // so the parents' visual mutation sets are empty even though a double-factor
    // (lethal) offspring is produced. The analyzer must rely on the
    // authoritative per-offspring doubleFactorIds instead of a visual pre-check.
    test('flags DF Feather Duster from carrier x carrier (empty visual sets)',
        () {
      final result = analyzer.analyze(
        fatherMutations: const {},
        motherMutations: const {},
        offspringResults: [
          _featherDuster(0.25),
          _offspring(phenotype: 'Normal', probability: 0.75),
        ],
      );

      expect(result.hasWarnings, isTrue);
      expect(
        result.warnings.map((w) => w.combination.id),
        contains('df_feather_duster'),
      );
      expect(result.totalAffectedProbability, closeTo(0.25, 1e-9));
      expect(result.highestSeverity, LethalSeverity.lethal);
    });

    test('does not flag Feather Duster when no offspring is double factor', () {
      final result = analyzer.analyze(
        fatherMutations: const {},
        motherMutations: const {},
        offspringResults: [
          _offspring(phenotype: 'Feather Duster (carrier)', probability: 0.5),
          _offspring(phenotype: 'Normal', probability: 0.5),
        ],
      );
      expect(result.hasWarnings, isFalse);
    });
  });

  group('severity ordering', () {
    test('lethal (feather duster) outranks sub-vital (crested)', () {
      final result = analyzer.analyze(
        fatherMutations: {'feather_duster', 'crested_tufted'},
        motherMutations: {'feather_duster', 'crested_half_circular'},
        offspringResults: [_featherDuster(0.25), _dfCrested(0.25)],
      );
      expect(result.highestSeverity, LethalSeverity.lethal);
    });

    test('crested-only cross is sub-vital, not lethal (v6)', () {
      final result = analyzer.analyze(
        fatherMutations: {'crested_tufted'},
        motherMutations: {'crested_half_circular'},
        offspringResults: [_dfCrested(1.0)],
      );
      expect(result.highestSeverity, LethalSeverity.subVital);
    });
  });

  group('affected probability', () {
    test('sums affected rates across distinct offspring', () {
      final result = analyzer.analyze(
        fatherMutations: {'feather_duster'},
        motherMutations: {'feather_duster'},
        offspringResults: [
          _featherDuster(0.25),
          _offspring(phenotype: 'Normal', probability: 0.75),
        ],
      );
      // 0.25 * 1.0 = 0.25
      expect(result.totalAffectedProbability, closeTo(0.25, 0.0001));
    });

    test('double-counting guard: one offspring hit by two combos counts once',
        () {
      // An offspring that is DF for feather-duster AND a double-factor crest at
      // once is matched by both df_feather_duster and df_crested. The analyzer
      // keeps only the highest per-offspring impact, so it is not double-counted.
      final both = _offspring(
        phenotype: 'Feather Duster + DF Crested',
        probability: 0.10,
        doubleFactorIds: {
          GeneticsConstants.mutFeatherDuster,
          'crested_tufted',
          'crested_half_circular',
        },
      );
      final plainDuster = _featherDuster(0.20);
      final result = analyzer.analyze(
        fatherMutations: {'feather_duster', 'crested_tufted'},
        motherMutations: {'feather_duster', 'crested_half_circular'},
        offspringResults: [both, plainDuster],
      );

      expect(
        result.warnings.where((w) => w.combination.id == 'df_feather_duster'),
        isNotEmpty,
      );
      expect(
        result.warnings.where((w) => w.combination.id == 'df_crested'),
        isNotEmpty,
      );
      // max(0.10, 0.10) + 0.20 = 0.30, not 0.40.
      expect(result.totalAffectedProbability, closeTo(0.30, 0.0001));
    });
  });

  group('empty offspring list', () {
    test('no warnings when there are no offspring to attach to', () {
      final result = analyzer.analyze(
        fatherMutations: {'feather_duster'},
        motherMutations: {'feather_duster'},
        offspringResults: const [],
      );
      expect(result.hasWarnings, isFalse);
      expect(result.totalAffectedProbability, 0.0);
    });
  });
}
