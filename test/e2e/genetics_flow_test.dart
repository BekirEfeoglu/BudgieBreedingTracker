@Tags(['e2e'])
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/inbreeding_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_history_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_calculation_providers.dart';

import '../helpers/e2e_test_harness.dart';
import '../helpers/test_helpers.dart';

Future<T> _awaitProviderValue<T>(
  ProviderContainer container,
  dynamic provider,
) async {
  final completer = Completer<T>();
  late final ProviderSubscription<AsyncValue<T>> subscription;
  subscription = container.listen<AsyncValue<T>>(provider, (_, next) {
    if (next.hasValue && !completer.isCompleted) {
      completer.complete(next.requireValue);
      return;
    }
    if (next.hasError && !completer.isCompleted) {
      completer.completeError(
        next.error!,
        next.stackTrace ?? StackTrace.current,
      );
    }
  }, fireImmediately: true);
  try {
    return await completer.future.timeout(const Duration(seconds: 5));
  } finally {
    subscription.close();
  }
}

void main() {
  ensureE2EBinding();

  group('Genetics Flow E2E', () {
    test(
      'GIVEN genetics screen WHEN father is ino-carrier and mother visual ino THEN punnett square and 25-25-25-25 split are produced',
      () {
        const calculator = MendelianCalculator();

        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'ino': AlleleState.carrier},
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'ino': AlleleState.visual},
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );
        final punnett = calculator.buildPunnettSquareFromGenotypes(
          father: father,
          mother: mother,
          mutationId: 'ino',
        );

        expect(punnett, isNotNull);
        expect(results.length, 4);
        for (final result in results) {
          expect(result.probability, closeTo(0.25, 0.001));
        }
        expect(results.where((r) => r.sex == OffspringSex.male).length, 2);
        expect(results.where((r) => r.sex == OffspringSex.female).length, 2);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN multi-locus parent input WHEN calculation runs THEN epistasis and multi-locus phenotype percentages are generated',
      () {
        final container = createTestContainer();
        addTearDown(container.dispose);

        container
            .read(fatherGenotypeProvider.notifier)
            .state = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'blue': AlleleState.visual,
            'dark_factor': AlleleState.carrier,
          },
        );
        container
            .read(motherGenotypeProvider.notifier)
            .state = ParentGenotype(
          gender: BirdGender.female,
          mutations: {
            'dilute': AlleleState.visual,
            'blue': AlleleState.carrier,
          },
        );

        final results = container.read(offspringResultsProvider);
        final loci = container.read(availablePunnettLociProvider);

        expect(results, isNotNull);
        expect(results!, isNotEmpty);
        expect(loci.length, greaterThanOrEqualTo(2));

        final total = results.fold<double>(
          0,
          (sum, item) => sum + item.probability,
        );
        expect(total, closeTo(1.0, 0.001));
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN selected existing pair WHEN genotypes are loaded to providers THEN calculation uses the selected pair data',
      () {
        final container = createTestContainer();
        addTearDown(container.dispose);

        container.read(selectedFatherBirdNameProvider.notifier).state =
            'Sultan';
        container.read(selectedMotherBirdNameProvider.notifier).state =
            'Papatya';
        container
            .read(fatherGenotypeProvider.notifier)
            .state = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'ino': AlleleState.visual},
        );
        container
            .read(motherGenotypeProvider.notifier)
            .state = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'ino': AlleleState.carrier},
        );

        final results = container.read(offspringResultsProvider);

        expect(container.read(selectedFatherBirdNameProvider), 'Sultan');
        expect(container.read(selectedMotherBirdNameProvider), 'Papatya');
        expect(results, isNotNull);
        expect(results!, isNotEmpty);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN three previous calculations WHEN history screen data is requested THEN 3 entries are listed and can be parsed for rerun',
      () async {
        final container = createTestContainer();
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

        final saver = container.read(geneticsHistorySaveProvider.notifier);
        await saver.saveCurrentCalculation(notes: 'calc-1');
        await saver.saveCurrentCalculation(notes: 'calc-2');
        await saver.saveCurrentCalculation(notes: 'calc-3');

        final entries = await _awaitProviderValue<List<GeneticsHistory>>(
          container,
          geneticsHistoryStreamProvider('test-user'),
        );
        expect(entries.length, 3);

        final parsed = parseHistoryResults(entries.first.resultsJson);
        expect(parsed, isNotEmpty);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN related birds in pedigree WHEN inbreeding analysis runs THEN coefficient is shown and warning condition over 12.5 percent is detectable',
      () {
        final pedigree = createInbredPedigree();

        final inbreeding = calculateInbreedingForBird('subject', pedigree);
        final showWarning = inbreeding.coefficient >= 0.125;

        expect(inbreeding.coefficient, closeTo(0.125, 0.001));
        expect(inbreeding.risk, InbreedingRisk.low);
        expect(showWarning, isTrue);
      },
      timeout: e2eTimeout,
    );
  });
}
