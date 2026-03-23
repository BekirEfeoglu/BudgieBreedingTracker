import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';

import '../../../helpers/mocks.dart';

Egg _egg({
  required String id,
  EggStatus status = EggStatus.laid,
  String? incubationId,
  String? clutchId,
  int? eggNumber,
  DateTime? layDate,
}) {
  return Egg(
    id: id,
    userId: 'user-1',
    status: status,
    incubationId: incubationId,
    clutchId: clutchId,
    eggNumber: eggNumber,
    layDate: layDate ?? DateTime(2024, 1, 1),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  late MockEggRepository repo;

  setUp(() {
    repo = MockEggRepository();
  });

  ProviderContainer makeContainer({
    List<dynamic> overrides = const [],
  }) {
    return ProviderContainer(
      overrides: [
        eggRepositoryProvider.overrideWithValue(repo),
        ...overrides.cast(),
      ],
    );
  }

  group('eggsStreamProvider', () {
    test('returns eggs from repository watchAll', () async {
      final eggs = [_egg(id: 'e1'), _egg(id: 'e2'), _egg(id: 'e3')];
      when(() => repo.watchAll('user-1')).thenAnswer(
        (_) => Stream.value(eggs),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(eggsStreamProvider('user-1'), (_, __) {});
      final result = await container.read(
        eggsStreamProvider('user-1').future,
      );

      expect(result, hasLength(3));
      expect(result.map((e) => e.id), containsAll(['e1', 'e2', 'e3']));
    });

    test('returns empty list when no eggs exist', () async {
      when(() => repo.watchAll('user-1')).thenAnswer(
        (_) => Stream.value([]),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(eggsStreamProvider('user-1'), (_, __) {});
      final result = await container.read(
        eggsStreamProvider('user-1').future,
      );

      expect(result, isEmpty);
    });

    test('streams multiple emissions reactively', () async {
      final controller = StreamController<List<Egg>>.broadcast();
      when(() => repo.watchAll('user-1')).thenAnswer(
        (_) => controller.stream,
      );

      final container = makeContainer();
      addTearDown(() {
        container.dispose();
        controller.close();
      });

      final emissions = <AsyncValue<List<Egg>>>[];
      container.listen(eggsStreamProvider('user-1'), (_, next) {
        emissions.add(next);
      });

      controller.add([_egg(id: 'e1')]);
      await Future<void>.delayed(Duration.zero);

      controller.add([_egg(id: 'e1'), _egg(id: 'e2')]);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, isNotEmpty);
    });

    test('different userIds create separate providers', () async {
      when(() => repo.watchAll('user-1')).thenAnswer(
        (_) => Stream.value([_egg(id: 'e1')]),
      );
      when(() => repo.watchAll('user-2')).thenAnswer(
        (_) => Stream.value([_egg(id: 'e2'), _egg(id: 'e3')]),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(eggsStreamProvider('user-1'), (_, __) {});
      container.listen(eggsStreamProvider('user-2'), (_, __) {});

      final user1Eggs = await container.read(
        eggsStreamProvider('user-1').future,
      );
      final user2Eggs = await container.read(
        eggsStreamProvider('user-2').future,
      );

      expect(user1Eggs, hasLength(1));
      expect(user2Eggs, hasLength(2));
    });
  });

  group('eggsForIncubationProvider', () {
    test('returns eggs filtered by incubation id', () async {
      final eggs = [
        _egg(id: 'e1', incubationId: 'inc-1'),
        _egg(id: 'e2', incubationId: 'inc-1'),
      ];
      when(() => repo.watchByIncubation('inc-1')).thenAnswer(
        (_) => Stream.value(eggs),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(eggsForIncubationProvider('inc-1'), (_, __) {});
      final result = await container.read(
        eggsForIncubationProvider('inc-1').future,
      );

      expect(result, hasLength(2));
      verify(() => repo.watchByIncubation('inc-1')).called(1);
    });

    test('returns empty list for incubation with no eggs', () async {
      when(() => repo.watchByIncubation('inc-empty')).thenAnswer(
        (_) => Stream.value([]),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(eggsForIncubationProvider('inc-empty'), (_, __) {});
      final result = await container.read(
        eggsForIncubationProvider('inc-empty').future,
      );

      expect(result, isEmpty);
    });

    test('different incubation ids are independent', () async {
      when(() => repo.watchByIncubation('inc-1')).thenAnswer(
        (_) => Stream.value([_egg(id: 'e1', incubationId: 'inc-1')]),
      );
      when(() => repo.watchByIncubation('inc-2')).thenAnswer(
        (_) => Stream.value([
          _egg(id: 'e2', incubationId: 'inc-2'),
          _egg(id: 'e3', incubationId: 'inc-2'),
        ]),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(eggsForIncubationProvider('inc-1'), (_, __) {});
      container.listen(eggsForIncubationProvider('inc-2'), (_, __) {});

      final inc1 = await container.read(
        eggsForIncubationProvider('inc-1').future,
      );
      final inc2 = await container.read(
        eggsForIncubationProvider('inc-2').future,
      );

      expect(inc1, hasLength(1));
      expect(inc2, hasLength(2));
    });
  });

  group('eggActionsProvider - deleteEgg', () {
    test('sets loading true during deletion', () async {
      final completer = Completer<void>();
      when(() => repo.remove(any())).thenAnswer((_) => completer.future);

      final container = makeContainer();
      addTearDown(container.dispose);

      final future = container.read(eggActionsProvider.notifier).deleteEgg(
        'e1',
      );

      final state = container.read(eggActionsProvider);
      expect(state.isLoading, isTrue);
      expect(state.error, isNull);

      completer.complete();
      await future;
    });

    test('sets isSuccess true after successful deletion', () async {
      when(() => repo.remove('e1')).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).deleteEgg('e1');

      final state = container.read(eggActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isTrue);
      expect(state.error, isNull);
    });

    test('sets error on failure', () async {
      when(() => repo.remove('e-fail')).thenThrow(
        StateError('Network error'),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).deleteEgg('e-fail');

      final state = container.read(eggActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.error, contains('errors.unknown'));
    });

    test('reset clears all state', () async {
      when(() => repo.remove('e1')).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).deleteEgg('e1');
      container.read(eggActionsProvider.notifier).reset();

      final state = container.read(eggActionsProvider);
      expect(state, const EggActionsState());
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNull);
      expect(state.chickCreated, isFalse);
    });

    test('multiple sequential deletes work independently', () async {
      when(() => repo.remove(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).deleteEgg('e1');
      expect(container.read(eggActionsProvider).isSuccess, isTrue);

      container.read(eggActionsProvider.notifier).reset();

      await container.read(eggActionsProvider.notifier).deleteEgg('e2');
      expect(container.read(eggActionsProvider).isSuccess, isTrue);

      verify(() => repo.remove('e1')).called(1);
      verify(() => repo.remove('e2')).called(1);
    });
  });

  group('EggActionsState', () {
    test('default state has correct initial values', () {
      const state = EggActionsState();

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.chickCreated, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      const state = EggActionsState();
      final updated = state.copyWith(isLoading: true);

      expect(updated.isLoading, isTrue);
      expect(updated.isSuccess, isFalse);
      expect(updated.chickCreated, isFalse);
      expect(updated.error, isNull);
    });

    test('copyWith replaces specified fields', () {
      const state = EggActionsState();
      final updated = state.copyWith(
        isLoading: true,
        isSuccess: true,
        chickCreated: true,
      );

      expect(updated.isLoading, isTrue);
      expect(updated.isSuccess, isTrue);
      expect(updated.chickCreated, isTrue);
    });

    test('copyWith clears error when set to null', () {
      final state = const EggActionsState().copyWith(error: 'some error');
      expect(state.error, 'some error');

      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('copyWith with error string sets error correctly', () {
      const state = EggActionsState();
      final withError = state.copyWith(error: 'Something went wrong');

      expect(withError.error, 'Something went wrong');
      expect(withError.isLoading, isFalse);
      expect(withError.isSuccess, isFalse);
    });

    test('loading state transition pattern is correct', () {
      // Simulate: initial -> loading -> success
      const initial = EggActionsState();
      expect(initial.isLoading, isFalse);
      expect(initial.isSuccess, isFalse);

      final loading = initial.copyWith(
        isLoading: true,
        error: null,
        isSuccess: false,
      );
      expect(loading.isLoading, isTrue);
      expect(loading.isSuccess, isFalse);

      final success = loading.copyWith(isLoading: false, isSuccess: true);
      expect(success.isLoading, isFalse);
      expect(success.isSuccess, isTrue);
    });

    test('error state transition pattern is correct', () {
      // Simulate: initial -> loading -> error
      const initial = EggActionsState();
      final loading = initial.copyWith(
        isLoading: true,
        error: null,
        isSuccess: false,
      );
      final error = loading.copyWith(
        isLoading: false,
        error: 'Failed to delete',
      );

      expect(error.isLoading, isFalse);
      expect(error.isSuccess, isFalse);
      expect(error.error, 'Failed to delete');
    });
  });
}
