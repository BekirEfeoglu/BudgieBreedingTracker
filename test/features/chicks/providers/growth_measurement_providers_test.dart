import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/growth_measurement_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/growth_measurement_providers.dart';

class MockGrowthMeasurementRepository extends Mock
    implements GrowthMeasurementRepository {}

void main() {
  late MockGrowthMeasurementRepository repo;

  setUp(() {
    repo = MockGrowthMeasurementRepository();
    registerFallbackValue(
      GrowthMeasurement(
        id: '',
        chickId: '',
        userId: '',
        weight: 0,
        measurementDate: DateTime(2024),
      ),
    );
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [growthMeasurementRepositoryProvider.overrideWithValue(repo)],
    );
  }

  group('growthMeasurementsStreamProvider', () {
    test('delegates to repository.watchByChick', () async {
      final measurements = [
        GrowthMeasurement(
          id: 'm1',
          chickId: 'c1',
          userId: 'u1',
          weight: 25.0,
          measurementDate: DateTime(2024, 1, 1),
        ),
      ];
      when(
        () => repo.watchByChick('c1'),
      ).thenAnswer((_) => Stream.value(measurements));

      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(growthMeasurementsStreamProvider('c1'), (_, __) {});
      final result = await container.read(
        growthMeasurementsStreamProvider('c1').future,
      );

      expect(result, hasLength(1));
      expect(result.first.weight, 25.0);
    });
  });

  group('GrowthMeasurementActionsState', () {
    test('initial state has default values', () {
      const state = GrowthMeasurementActionsState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates fields', () {
      const state = GrowthMeasurementActionsState();
      final updated = state.copyWith(isLoading: true, error: 'err');
      expect(updated.isLoading, isTrue);
      expect(updated.error, 'err');
    });
  });

  group('GrowthMeasurementActionsNotifier', () {
    test('addMeasurement succeeds', () async {
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(growthMeasurementActionsProvider.notifier)
          .addMeasurement(
            chickId: 'c1',
            userId: 'u1',
            weight: 30.0,
            measurementDate: DateTime(2024, 3, 1),
          );

      expect(
        container.read(growthMeasurementActionsProvider).isSuccess,
        isTrue,
      );
    });

    test('addMeasurement sets error on failure', () async {
      when(() => repo.save(any())).thenThrow(Exception('fail'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(growthMeasurementActionsProvider.notifier)
          .addMeasurement(
            chickId: 'c1',
            userId: 'u1',
            weight: 30.0,
            measurementDate: DateTime(2024, 3, 1),
          );

      expect(container.read(growthMeasurementActionsProvider).error, isNotNull);
    });

    test('deleteMeasurement succeeds', () async {
      when(() => repo.remove(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(growthMeasurementActionsProvider.notifier)
          .deleteMeasurement('m1');

      expect(
        container.read(growthMeasurementActionsProvider).isSuccess,
        isTrue,
      );
    });

    test('reset clears state', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(growthMeasurementActionsProvider.notifier).reset();
      final state = container.read(growthMeasurementActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });
  });
}
