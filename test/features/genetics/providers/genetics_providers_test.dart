import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/genetics_history_dao.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_history_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';

class MockGeneticsHistoryDao extends Mock implements GeneticsHistoryDao {}

GeneticsHistory _history({String id = 'h1', String resultsJson = '[]'}) {
  return GeneticsHistory(
    id: id,
    userId: 'user-1',
    fatherGenotype: const {'blue': 'visual'},
    motherGenotype: const {'blue': 'carrier'},
    resultsJson: resultsJson,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_history());
  });

  group('genetics calculation providers', () {
    test('offspringResultsProvider is null when both parents are empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final results = container.read(offspringResultsProvider);
      expect(results, isNull);
    });

    test('calculates offspring results from parent genotypes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(fatherGenotypeProvider.notifier)
          .state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      container
          .read(motherGenotypeProvider.notifier)
          .state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.carrier},
      );

      final results = container.read(offspringResultsProvider);
      expect(results, isNotNull);
      expect(results!.isNotEmpty, isTrue);
      final total = results.fold<double>(
        0,
        (sum, item) => sum + item.probability,
      );
      expect(total, closeTo(1.0, 0.001));
    });

    test('availablePunnettLociProvider returns union of parent loci', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(fatherGenotypeProvider.notifier)
          .state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      container
          .read(motherGenotypeProvider.notifier)
          .state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'opaline': AlleleState.visual},
      );

      final loci = container.read(availablePunnettLociProvider);
      // 'blue' mutation maps to locusId 'blue_series' via MutationDatabase;
      // 'opaline' has no locusId so its id is used directly.
      expect(loci, containsAll(['blue_series', 'opaline']));
    });

    test('availablePunnettLociProvider returns deterministic sorted loci', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(fatherGenotypeProvider.notifier)
          .state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'opaline': AlleleState.visual},
      );
      container
          .read(motherGenotypeProvider.notifier)
          .state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.visual},
      );

      final loci = container.read(availablePunnettLociProvider);
      expect(loci, ['blue_series', 'opaline']);
    });

    test('punnettSquareProvider builds square for selected locus', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(fatherGenotypeProvider.notifier)
          .state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      container
          .read(motherGenotypeProvider.notifier)
          .state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.carrier},
      );
      container.read(selectedPunnettLocusProvider.notifier).state = 'blue';

      final square = container.read(punnettSquareProvider);
      expect(square, isNotNull);
      expect(square!.cells, isNotEmpty);
      expect(square.mutationName, isNotEmpty);
    });

    test('punnettSquareProvider falls back when selected locus is invalid', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(fatherGenotypeProvider.notifier)
          .state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      container
          .read(motherGenotypeProvider.notifier)
          .state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.carrier},
      );
      container.read(selectedPunnettLocusProvider.notifier).state = 'opaline';

      final effectiveLocus = container.read(effectivePunnettLocusProvider);
      final square = container.read(punnettSquareProvider);

      expect(effectiveLocus, 'blue_series');
      expect(square, isNotNull);
      expect(square!.mutationName, 'Blue Series');
    });

    test('offspringChartDataProvider maps results to chart items', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(fatherGenotypeProvider.notifier)
          .state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      container
          .read(motherGenotypeProvider.notifier)
          .state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.carrier},
      );

      final results = container.read(offspringResultsProvider)!;
      final chart = container.read(offspringChartDataProvider);

      expect(chart, hasLength(results.length));
      expect(chart.every((c) => c.value >= 0 && c.value <= 100), isTrue);
    });

    test(
      'epistasisInteractionsProvider extracts interactions from results',
      () {
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
      },
    );

    test('phenotypeColor maps known and unknown labels', () {
      expect(phenotypeColor('Albino'), AppColors.phenotypeAlbino);
      expect(phenotypeColor('Blue'), isNotNull);
      expect(phenotypeColor('UnknownPhenotype'), isNotNull);
    });

    test('parent mutation providers include only visual mutations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(fatherGenotypeProvider.notifier)
          .state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'ino': AlleleState.carrier, 'spangle': AlleleState.carrier},
      );
      container
          .read(motherGenotypeProvider.notifier)
          .state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'ino': AlleleState.visual, 'blue': AlleleState.carrier},
      );

      expect(container.read(fatherMutationsProvider), {'spangle'});
      expect(container.read(motherMutationsProvider), {'ino'});
    });

    test(
      'ino_x_ino warning is not emitted when only one parent is visual ino',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container
            .read(fatherGenotypeProvider.notifier)
            .state = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'ino': AlleleState.carrier},
        );
        container
            .read(motherGenotypeProvider.notifier)
            .state = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'ino': AlleleState.visual},
        );

        final analysis = container.read(lethalAnalysisProvider);
        expect(analysis, isNotNull);
        expect(
          analysis!.warnings.where((w) => w.combination.id == 'ino_x_ino'),
          isEmpty,
        );
      },
    );
  });

  group('genetics history parsing helpers', () {
    test('parseHistoryResults parses valid JSON list', () {
      final jsonList = jsonEncode([
        {
          'phenotype': 'Blue',
          'probability': 0.5,
          'genotype': 'bl/bl',
          'sex': 'male',
          'carriedMutations': ['opaline'],
        },
      ]);

      final parsed = parseHistoryResults(jsonList);
      expect(parsed, hasLength(1));
      expect(parsed.first.phenotype, 'Blue');
      expect(parsed.first.sex, OffspringSex.male);
      expect(parsed.first.carriedMutations, ['opaline']);
    });

    test('parseHistoryResults parses enriched genetics fields', () {
      final jsonList = jsonEncode([
        {
          'phenotype': 'Albino',
          'probability': 0.25,
          'sex': 'female',
          'isCarrier': true,
          'compoundPhenotype': 'Albino',
          'visualMutations': ['ino', 'blue'],
          'carriedMutations': ['opaline'],
          'maskedMutations': ['opaline'],
          'lethalCombinationIds': ['ino_x_ino'],
        },
      ]);

      final parsed = parseHistoryResults(jsonList);
      expect(parsed, hasLength(1));
      expect(parsed.first.isCarrier, isTrue);
      expect(parsed.first.visualMutations, ['ino', 'blue']);
      expect(parsed.first.maskedMutations, ['opaline']);
      expect(parsed.first.lethalCombinationIds, ['ino_x_ino']);
    });

    test('parseHistoryResults infers legacy carrier flag from phenotype', () {
      final jsonList = jsonEncode([
        {
          'phenotype': 'Blue (Opaline carrier)',
          'probability': 0.5,
          'sex': 'both',
        },
      ]);

      final parsed = parseHistoryResults(jsonList);
      expect(parsed, hasLength(1));
      expect(parsed.first.isCarrier, isTrue);
    });

    test('parseHistoryResults returns empty list on invalid JSON', () {
      expect(parseHistoryResults('not-json'), isEmpty);
    });

    test('parseStoredGenotype maps allele states correctly', () {
      final genotype = parseStoredGenotype(const {
        'blue': 'visual',
        'opaline': 'carrier',
        'fallback': 'unknown',
      }, BirdGender.male);

      expect(genotype.getState('blue'), AlleleState.visual);
      expect(genotype.getState('opaline'), AlleleState.carrier);
      expect(genotype.getState('fallback'), AlleleState.visual);
      expect(genotype.gender, BirdGender.male);
    });
  });

  group('GeneticsHistorySaveNotifier', () {
    late MockGeneticsHistoryDao dao;

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [
          geneticsHistoryDaoProvider.overrideWithValue(dao),
          currentUserIdProvider.overrideWithValue('user-1'),
        ],
      );
    }

    setUp(() {
      dao = MockGeneticsHistoryDao();
      when(() => dao.insertItem(any())).thenAnswer((_) async {});
      when(() => dao.softDelete(any())).thenAnswer((_) async {});
      when(() => dao.watchAll(any())).thenAnswer((_) => Stream.value([]));
      when(() => dao.watchById(any())).thenAnswer((_) => Stream.value(null));
    });

    test(
      'saveCurrentCalculation returns false when there are no results',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        final ok = await container
            .read(geneticsHistorySaveProvider.notifier)
            .saveCurrentCalculation();

        expect(ok, isFalse);
        verifyNever(() => dao.insertItem(any()));
      },
    );

    test(
      'saveCurrentCalculation inserts a history entry when results exist',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container
            .read(fatherGenotypeProvider.notifier)
            .state = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'blue': AlleleState.visual},
        );
        container
            .read(motherGenotypeProvider.notifier)
            .state = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'blue': AlleleState.carrier},
        );

        final ok = await container
            .read(geneticsHistorySaveProvider.notifier)
            .saveCurrentCalculation(notes: 'test-note');

        expect(ok, isTrue);
        final captured =
            verify(() => dao.insertItem(captureAny())).captured.single
                as GeneticsHistory;
        expect(captured.userId, 'user-1');
        expect(captured.notes, 'test-note');
        expect(captured.resultsJson, isNotEmpty);
        final decoded = jsonDecode(captured.resultsJson) as List<dynamic>;
        expect(decoded, isNotEmpty);
        final firstResult = decoded.first as Map<String, dynamic>;
        expect(firstResult['isCarrier'], isA<bool>());
      },
    );

    test('deleteEntry delegates to dao.softDelete', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(geneticsHistorySaveProvider.notifier)
          .deleteEntry('h1');

      verify(() => dao.softDelete('h1')).called(1);
    });

    test('history stream providers delegate to dao streams', () async {
      final sample = _history(
        resultsJson: jsonEncode(const [
          {'phenotype': 'Blue', 'probability': 1.0, 'sex': 'both'},
        ]),
      );
      when(
        () => dao.watchAll('user-1'),
      ).thenAnswer((_) => Stream.value([sample]));
      when(() => dao.watchById('h1')).thenAnswer((_) => Stream.value(sample));

      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(geneticsHistoryStreamProvider('user-1'), (_, __) {});
      final all = await container.read(
        geneticsHistoryStreamProvider('user-1').future,
      );
      container.listen(geneticsHistoryByIdProvider('h1'), (_, __) {});
      final byId = await container.read(
        geneticsHistoryByIdProvider('h1').future,
      );

      expect(all, hasLength(1));
      expect(byId?.id, 'h1');
      verify(() => dao.watchAll('user-1')).called(1);
      verify(() => dao.watchById('h1')).called(1);
    });
  });
}
