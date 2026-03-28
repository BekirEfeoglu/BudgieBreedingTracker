import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/viability_analyzer.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';

void main() {
  group('offspringChartDataProvider', () {
    test('returns empty list when offspringResults is null', () {
      final container = ProviderContainer(
        overrides: [offspringResultsProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(container.read(offspringChartDataProvider), isEmpty);
    });

    test('returns empty list when offspringResults is empty', () {
      final container = ProviderContainer(
        overrides: [offspringResultsProvider.overrideWithValue(const [])],
      );
      addTearDown(container.dispose);

      expect(container.read(offspringChartDataProvider), isEmpty);
    });

    test('maps results to chart items with correct probability scaling', () {
      final container = ProviderContainer(
        overrides: [
          offspringResultsProvider.overrideWithValue(const [
            OffspringResult(phenotype: 'Blue', probability: 0.5),
            OffspringResult(phenotype: 'Normal', probability: 0.5),
          ]),
        ],
      );
      addTearDown(container.dispose);

      final chart = container.read(offspringChartDataProvider);
      expect(chart, hasLength(2));
      expect(chart[0].label, 'Blue');
      expect(chart[0].value, 50.0);
      expect(chart[1].label, 'Normal');
      expect(chart[1].value, 50.0);
    });

    test('assigns color from visual mutations when available', () {
      final container = ProviderContainer(
        overrides: [
          offspringResultsProvider.overrideWithValue(const [
            OffspringResult(
              phenotype: 'Blue',
              probability: 1.0,
              visualMutations: ['blue'],
            ),
          ]),
        ],
      );
      addTearDown(container.dispose);

      final chart = container.read(offspringChartDataProvider);
      expect(chart.first.color, AppColors.budgieBlue);
    });

    test('falls back to phenotype color when no visual mutations', () {
      final container = ProviderContainer(
        overrides: [
          offspringResultsProvider.overrideWithValue(const [
            OffspringResult(
              phenotype: 'Normal',
              probability: 1.0,
              visualMutations: [],
            ),
          ]),
        ],
      );
      addTearDown(container.dispose);

      final chart = container.read(offspringChartDataProvider);
      expect(chart.first.color, AppColors.neutral500);
    });
  });

  group('viabilityAnalyzerProvider', () {
    test('returns a ViabilityAnalyzer instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final analyzer = container.read(viabilityAnalyzerProvider);
      expect(analyzer, isA<ViabilityAnalyzer>());
    });
  });

  group('lethalAnalysisProvider', () {
    test('returns null when offspring results are null', () {
      final container = ProviderContainer(
        overrides: [offspringResultsProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(container.read(lethalAnalysisProvider), isNull);
    });

    test('returns null when offspring results are empty', () {
      final container = ProviderContainer(
        overrides: [offspringResultsProvider.overrideWithValue(const [])],
      );
      addTearDown(container.dispose);

      expect(container.read(lethalAnalysisProvider), isNull);
    });

    test('returns analysis result for valid offspring results', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.carrier},
      );

      final analysis = container.read(lethalAnalysisProvider)!;
      expect(analysis.warnings, isEmpty);
    });
  });

  group('enrichedOffspringResultsProvider', () {
    test('returns null when offspring results are null', () {
      final container = ProviderContainer(
        overrides: [offspringResultsProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(container.read(enrichedOffspringResultsProvider), isNull);
    });

    test('returns original results when no lethal warnings', () {
      const results = [
        OffspringResult(phenotype: 'Blue', probability: 0.5),
        OffspringResult(phenotype: 'Normal', probability: 0.5),
      ];
      final container = ProviderContainer(
        overrides: [offspringResultsProvider.overrideWithValue(results)],
      );
      addTearDown(container.dispose);

      final enriched = container.read(enrichedOffspringResultsProvider)!;
      expect(enriched, hasLength(2));
      // Results without warnings should have empty lethalCombinationIds
      for (final result in enriched) {
        expect(result.lethalCombinationIds, isEmpty);
      }
    });

    test(
      'enriches results with lethal combination IDs when warnings present',
      () {
        // Use ino visual on both parents to trigger ino_x_ino warning
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'ino': AlleleState.visual},
        );
        container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'ino': AlleleState.visual},
        );

        final analysis = container.read(lethalAnalysisProvider)!;
        final enriched = container.read(enrichedOffspringResultsProvider)!;

        expect(analysis.hasWarnings, isTrue);
        final anyHasLethalIds = enriched.any(
          (r) => r.lethalCombinationIds.isNotEmpty,
        );
        expect(anyHasLethalIds, isTrue);
      },
    );
  });

  group('epistasisInteractionsProvider', () {
    test('returns empty list when offspring results are null', () {
      final container = ProviderContainer(
        overrides: [offspringResultsProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(container.read(epistasisInteractionsProvider), isEmpty);
    });

    test('returns empty list when offspring results are empty', () {
      final container = ProviderContainer(
        overrides: [offspringResultsProvider.overrideWithValue(const [])],
      );
      addTearDown(container.dispose);

      expect(container.read(epistasisInteractionsProvider), isEmpty);
    });

    test('extracts interactions from offspring with multiple mutations', () {
      final container = ProviderContainer(
        overrides: [
          offspringResultsProvider.overrideWithValue(const [
            OffspringResult(
              phenotype: 'Albino',
              probability: 1.0,
              visualMutations: ['ino', 'blue'],
            ),
          ]),
        ],
      );
      addTearDown(container.dispose);

      final interactions = container.read(epistasisInteractionsProvider);
      expect(interactions, isNotEmpty);
      expect(interactions.any((i) => i.resultName == 'Albino'), isTrue);
    });

    test('returns empty for results with no visual mutations', () {
      final container = ProviderContainer(
        overrides: [
          offspringResultsProvider.overrideWithValue(const [
            OffspringResult(
              phenotype: 'Normal',
              probability: 1.0,
              visualMutations: [],
            ),
          ]),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(epistasisInteractionsProvider), isEmpty);
    });

    test('deduplicates interactions by result name', () {
      final container = ProviderContainer(
        overrides: [
          offspringResultsProvider.overrideWithValue(const [
            OffspringResult(
              phenotype: 'Albino Male',
              probability: 0.5,
              sex: OffspringSex.male,
              visualMutations: ['ino', 'blue'],
            ),
            OffspringResult(
              phenotype: 'Albino Female',
              probability: 0.5,
              sex: OffspringSex.female,
              visualMutations: ['ino', 'blue'],
            ),
          ]),
        ],
      );
      addTearDown(container.dispose);

      final interactions = container.read(epistasisInteractionsProvider);
      final albinoCount = interactions
          .where((i) => i.resultName == 'Albino')
          .length;
      expect(albinoCount, 1);
    });

    test('sorts interactions by highest probability', () {
      final container = ProviderContainer(
        overrides: [
          offspringResultsProvider.overrideWithValue(const [
            OffspringResult(
              phenotype: 'Lacewing',
              probability: 0.25,
              visualMutations: ['ino', 'cinnamon'],
            ),
            OffspringResult(
              phenotype: 'Albino',
              probability: 0.75,
              visualMutations: ['ino', 'blue'],
            ),
          ]),
        ],
      );
      addTearDown(container.dispose);

      final interactions = container.read(epistasisInteractionsProvider);
      expect(interactions.first.resultName, 'Albino');
      expect(
        interactions.map((interaction) => interaction.resultName),
        contains('Lacewing'),
      );
    });

    test('skips offspring with single visual mutation (no interaction)', () {
      final container = ProviderContainer(
        overrides: [
          offspringResultsProvider.overrideWithValue(const [
            OffspringResult(
              phenotype: 'Blue',
              probability: 1.0,
              visualMutations: ['blue'],
            ),
          ]),
        ],
      );
      addTearDown(container.dispose);

      // Blue alone does not create epistatic interactions
      // The EpistasisEngine needs multiple mutations to find interactions
      final interactions = container.read(epistasisInteractionsProvider);
      expect(interactions, isEmpty);
    });
  });
}
