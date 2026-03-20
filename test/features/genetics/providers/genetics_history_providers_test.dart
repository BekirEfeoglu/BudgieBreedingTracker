import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_history_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockGeneticsHistoryDao mockDao;

  setUp(() {
    mockDao = MockGeneticsHistoryDao();
  });

  group('geneticsHistoryStreamProvider', () {
    test('delegates to dao.watchAll', () async {
      const history = GeneticsHistory(
        id: 'hist-1',
        userId: 'user-1',
        fatherGenotype: {},
        motherGenotype: {},
        resultsJson: '[]',
      );

      when(
        () => mockDao.watchAll('user-1'),
      ).thenAnswer((_) => Stream.value([history]));

      final container = ProviderContainer(
        overrides: [geneticsHistoryDaoProvider.overrideWithValue(mockDao)],
      );
      addTearDown(container.dispose);

      // Keep provider alive until future resolves (Riverpod 3 auto-disposal)
      container.listen(geneticsHistoryStreamProvider('user-1'), (_, __) {});
      final result = await container.read(
        geneticsHistoryStreamProvider('user-1').future,
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'hist-1');
    });

    test('delegates to dao.watchAll for empty list', () async {
      when(
        () => mockDao.watchAll('user-1'),
      ).thenAnswer((_) => Stream.value([]));

      final container = ProviderContainer(
        overrides: [geneticsHistoryDaoProvider.overrideWithValue(mockDao)],
      );
      addTearDown(container.dispose);

      // Keep provider alive until future resolves (Riverpod 3 auto-disposal)
      container.listen(geneticsHistoryStreamProvider('user-1'), (_, __) {});
      final result = await container.read(
        geneticsHistoryStreamProvider('user-1').future,
      );
      expect(result, isEmpty);
    });
  });

  group('GeneticsHistorySaveNotifier.deleteEntry', () {
    test('calls dao.softDelete with the given id', () async {
      when(() => mockDao.softDelete('hist-1')).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [geneticsHistoryDaoProvider.overrideWithValue(mockDao)],
      );
      addTearDown(container.dispose);

      await container
          .read(geneticsHistorySaveProvider.notifier)
          .deleteEntry('hist-1');

      verify(() => mockDao.softDelete('hist-1')).called(1);
    });

    test('sets state to AsyncData after successful delete', () async {
      when(() => mockDao.softDelete(any())).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [geneticsHistoryDaoProvider.overrideWithValue(mockDao)],
      );
      addTearDown(container.dispose);

      await container
          .read(geneticsHistorySaveProvider.notifier)
          .deleteEntry('hist-1');

      final state = container.read(geneticsHistorySaveProvider);
      expect(state, isA<AsyncData<void>>());
    });

    test('sets state to AsyncError when dao throws', () async {
      when(() => mockDao.softDelete(any())).thenThrow(Exception('DB error'));

      final container = ProviderContainer(
        overrides: [geneticsHistoryDaoProvider.overrideWithValue(mockDao)],
      );
      addTearDown(container.dispose);

      await container
          .read(geneticsHistorySaveProvider.notifier)
          .deleteEntry('hist-1');

      final state = container.read(geneticsHistorySaveProvider);
      expect(state, isA<AsyncError<void>>());
    });
  });

  group('parseHistoryResults', () {
    test('parses valid JSON list correctly', () {
      const json =
          '[{"phenotype":"Lutino","probability":0.5,"genotype":"Zl Z+","sex":"male"}]';
      final results = parseHistoryResults(json);
      expect(results, hasLength(1));
      expect(results.first.phenotype, 'Lutino');
      expect(results.first.probability, 0.5);
      expect(results.first.genotype, 'Zl Z+');
    });

    test('returns empty list for invalid JSON', () {
      final results = parseHistoryResults('not-json');
      expect(results, isEmpty);
    });

    test('returns empty list for non-list JSON', () {
      final results = parseHistoryResults('{"key":"value"}');
      expect(results, isEmpty);
    });

    test('returns empty list for empty JSON array', () {
      final results = parseHistoryResults('[]');
      expect(results, isEmpty);
    });

    test('handles missing optional fields gracefully', () {
      const json = '[{"phenotype":"Green","probability":1.0}]';
      final results = parseHistoryResults(json);
      expect(results, hasLength(1));
      expect(results.first.phenotype, 'Green');
      expect(results.first.probability, 1.0);
      expect(results.first.genotype, isNull);
      expect(results.first.compoundPhenotype, isNull);
      expect(results.first.carriedMutations, isEmpty);
    });

    test('parses enriched optional mutation fields', () {
      const json = '''[
        {
          "phenotype":"Albino",
          "probability":0.25,
          "sex":"female",
          "isCarrier":true,
          "visualMutations":["ino","blue"],
          "maskedMutations":["opaline"],
          "lethalCombinationIds":["ino_x_ino"]
        }
      ]''';
      final results = parseHistoryResults(json);
      expect(results, hasLength(1));
      expect(results.first.isCarrier, isTrue);
      expect(results.first.visualMutations, ['ino', 'blue']);
      expect(results.first.maskedMutations, ['opaline']);
      expect(results.first.lethalCombinationIds, ['ino_x_ino']);
    });

    test('infers carrier from legacy phenotype string when flag is absent', () {
      const json = '[{"phenotype":"Blue (Opaline carrier)","probability":0.5}]';
      final results = parseHistoryResults(json);
      expect(results, hasLength(1));
      expect(results.first.isCarrier, isTrue);
    });

    test('parses multiple results', () {
      const json = '''[
        {"phenotype":"Lutino","probability":0.5,"sex":"female"},
        {"phenotype":"Normal","probability":0.5,"sex":"male"}
      ]''';
      final results = parseHistoryResults(json);
      expect(results, hasLength(2));
    });
  });

  group('parseStoredGenotype', () {
    test('converts visual allele state', () {
      // 'lutino' is a legacy alias that resolves to canonical ID 'ino'
      final genotype = parseStoredGenotype({
        'lutino': 'visual',
      }, BirdGender.male);
      expect(genotype.mutations['ino'], AlleleState.visual);
      expect(genotype.gender, BirdGender.male);
    });

    test('converts carrier allele state', () {
      // 'lutino' is a legacy alias that resolves to canonical ID 'ino'
      final genotype = parseStoredGenotype({
        'lutino': 'carrier',
      }, BirdGender.female);
      expect(genotype.mutations['ino'], AlleleState.carrier);
      expect(genotype.gender, BirdGender.female);
    });

    test('converts split allele state', () {
      final genotype = parseStoredGenotype({
        'cinnamon': 'split',
      }, BirdGender.male);
      expect(genotype.mutations['cinnamon'], AlleleState.split);
    });

    test('defaults to visual for unknown allele string', () {
      final genotype = parseStoredGenotype({
        'opaline': 'unknown_state',
      }, BirdGender.male);
      expect(genotype.mutations['opaline'], AlleleState.visual);
    });

    test('converts multiple mutations', () {
      // 'lutino' resolves to 'ino'; 'opaline' stays as 'opaline'
      final genotype = parseStoredGenotype({
        'lutino': 'visual',
        'opaline': 'carrier',
      }, BirdGender.female);
      expect(genotype.mutations.length, 2);
      expect(genotype.mutations['ino'], AlleleState.visual);
      expect(genotype.mutations['opaline'], AlleleState.carrier);
    });

    test('returns empty ParentGenotype for empty map', () {
      final genotype = parseStoredGenotype({}, BirdGender.male);
      expect(genotype.mutations, isEmpty);
    });
  });
}
