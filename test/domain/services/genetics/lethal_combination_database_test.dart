import 'package:budgie_breeding_tracker/domain/services/genetics/lethal_combination_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

OffspringResult _offspring({
  required String phenotype,
  required double probability,
  List<String> visualMutations = const [],
  String? compoundPhenotype,
  Set<String> doubleFactorIds = const {},
}) {
  return OffspringResult(
    phenotype: phenotype,
    probability: probability,
    visualMutations: visualMutations,
    compoundPhenotype: compoundPhenotype,
    doubleFactorIds: doubleFactorIds,
  );
}

void main() {
  group('LethalSeverity.labelKey', () {
    test('maps each severity to the expected localization key', () {
      expect(LethalSeverity.lethal.labelKey, 'genetics.lethal_severity_lethal');
      expect(
        LethalSeverity.semiLethal.labelKey,
        'genetics.lethal_severity_semi_lethal',
      );
      expect(
        LethalSeverity.subVital.labelKey,
        'genetics.lethal_severity_sub_vital',
      );
    });
  });

  group('LethalCombinationDatabase.getById', () {
    test('returns known combinations and null for unknown id', () {
      final crested = LethalCombinationDatabase.getById('df_crested');
      final featherDuster = LethalCombinationDatabase.getById(
        'df_feather_duster',
      );
      final unknown = LethalCombinationDatabase.getById('missing');

      expect(crested, isNotNull);
      // v6: crest is sub-vital (MUTAVI K10), not lethal.
      expect(crested!.severity, LethalSeverity.subVital);
      expect(featherDuster, isNotNull);
      expect(featherDuster!.severity, LethalSeverity.lethal);
      expect(unknown, isNull);
    });

    test('v6 removed the false-positive viability warnings', () {
      // Healthy homozygous pairings are no longer flagged (see v6 audit).
      expect(LethalCombinationDatabase.getById('df_spangle'), isNull);
      expect(LethalCombinationDatabase.getById('ino_x_ino'), isNull);
      expect(LethalCombinationDatabase.getById('pallid_x_pallid'), isNull);
      expect(
        LethalCombinationDatabase.getById('texas_clearbody_x_texas_clearbody'),
        isNull,
      );
    });
  });

  group('ViabilityAnalyzer.analyze', () {
    late ViabilityAnalyzer analyzer;

    setUp(() {
      analyzer = const ViabilityAnalyzer();
    });

    test(
      'returns an empty analysis when no lethal combinations are matched',
      () {
        final analysis = analyzer.analyze(
          fatherMutations: const {},
          motherMutations: const {},
          offspringResults: [
            _offspring(
              phenotype: 'Blue',
              probability: 1.0,
              visualMutations: const ['blue'],
            ),
          ],
        );

        expect(analysis.hasWarnings, isFalse);
        expect(analysis.warnings, isEmpty);
        expect(analysis.highestSeverity, isNull);
        expect(analysis.totalAffectedProbability, 0.0);
      },
    );

    test('does not flag healthy ino x ino (removed in v6)', () {
      final analysis = analyzer.analyze(
        fatherMutations: const {'ino'},
        motherMutations: const {'ino'},
        offspringResults: [
          _offspring(phenotype: 'Ino', probability: 0.6),
          _offspring(phenotype: 'Ino', probability: 0.4),
        ],
      );

      // v6: Ino × Ino is a healthy, standard pairing — no viability warning.
      expect(analysis.hasWarnings, isFalse);
      expect(analysis.warnings, isEmpty);
    });

    test('flags the double-factor feather-duster offspring as lethal', () {
      final analysis = analyzer.analyze(
        fatherMutations: const {'feather_duster'},
        motherMutations: const {'feather_duster'},
        offspringResults: [
          _offspring(
            phenotype: 'Feather Duster',
            probability: 0.25,
            visualMutations: const ['feather_duster'],
            doubleFactorIds: const {'feather_duster'},
          ),
          _offspring(phenotype: 'Normal', probability: 0.75),
        ],
      );

      expect(analysis.warnings, hasLength(1));
      expect(analysis.warnings.single.combination.id, 'df_feather_duster');
      expect(analysis.highestSeverity, LethalSeverity.lethal);
      expect(analysis.totalAffectedProbability, closeTo(0.25, 0.0001));
    });

    test(
      'flags only the double-factor crested offspring, not the single factor',
      () {
        final analysis = analyzer.analyze(
          fatherMutations: const {'crested_tufted'},
          motherMutations: const {'crested_full_circular'},
          offspringResults: [
            _offspring(
              phenotype: 'DF Crested',
              probability: 0.25,
              visualMutations: const ['crested_tufted'],
              doubleFactorIds: const {'crested_tufted', 'crested_full_circular'},
            ),
            _offspring(phenotype: 'Crested', probability: 0.75),
          ],
        );

        expect(analysis.warnings, hasLength(1));
        expect(analysis.warnings.single.combination.id, 'df_crested');
        // v6: crest is sub-vital, not lethal.
        expect(analysis.highestSeverity, LethalSeverity.subVital);
        expect(analysis.totalAffectedProbability, closeTo(0.25, 0.0001));
      },
    );

    test('sums the affected probability across distinct offspring', () {
      final analysis = analyzer.analyze(
        fatherMutations: const {'feather_duster', 'crested_tufted'},
        motherMutations: const {'feather_duster', 'crested_half_circular'},
        offspringResults: [
          _offspring(
            phenotype: 'Feather Duster',
            probability: 0.25,
            visualMutations: const ['feather_duster'],
            doubleFactorIds: const {'feather_duster'},
          ),
          _offspring(
            phenotype: 'DF Crested',
            probability: 0.25,
            visualMutations: const ['crested_tufted'],
            doubleFactorIds: const {'crested_tufted', 'crested_half_circular'},
          ),
        ],
      );

      expect(
        analysis.warnings.where((w) => w.combination.id == 'df_feather_duster'),
        hasLength(1),
      );
      expect(
        analysis.warnings.where((w) => w.combination.id == 'df_crested'),
        hasLength(1),
      );
      expect(analysis.totalAffectedProbability, closeTo(0.5, 0.0001));
    });

    test(
      'reports lethal as highest severity when lethal and sub-vital coexist',
      () {
        final analysis = analyzer.analyze(
          fatherMutations: const {'feather_duster', 'crested_tufted'},
          motherMutations: const {'feather_duster', 'crested_half_circular'},
          offspringResults: [
            _offspring(
              phenotype: 'Feather Duster',
              probability: 0.25,
              visualMutations: const ['feather_duster'],
              doubleFactorIds: const {'feather_duster'},
            ),
            _offspring(
              phenotype: 'DF Crested',
              probability: 0.25,
              visualMutations: const ['crested_tufted'],
              doubleFactorIds: const {'crested_tufted', 'crested_half_circular'},
            ),
          ],
        );

        expect(
          analysis.warnings.where((w) => w.combination.id == 'df_feather_duster'),
          hasLength(1),
        );
        expect(
          analysis.warnings.where((w) => w.combination.id == 'df_crested'),
          hasLength(1),
        );
        // Lethal (feather duster) outranks sub-vital (crested).
        expect(analysis.highestSeverity, LethalSeverity.lethal);
      },
    );
  });
}
