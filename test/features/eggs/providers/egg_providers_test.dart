import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';

import '../../../helpers/mocks.dart';

Egg _egg({required String id, String? incubationId}) {
  return Egg(
    id: id,
    userId: 'user-1',
    layDate: DateTime(2024, 1, 1),
    incubationId: incubationId,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  late MockEggRepository repo;

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [eggRepositoryProvider.overrideWithValue(repo)],
    );
  }

  setUp(() {
    repo = MockEggRepository();
    when(
      () => repo.watchAll(any()),
    ).thenAnswer((_) => Stream.value([_egg(id: 'e1'), _egg(id: 'e2')]));
    when(
      () => repo.watchByIncubation(any()),
    ).thenAnswer((_) => Stream.value([_egg(id: 'e3', incubationId: 'inc-1')]));
    when(() => repo.remove(any())).thenAnswer((_) async {});
  });

  group('stream providers', () {
    test('eggsStreamProvider delegates to repository.watchAll', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(eggsStreamProvider('user-1'), (_, __) {});
      final eggs = await container.read(eggsStreamProvider('user-1').future);

      expect(eggs, hasLength(2));
      verify(() => repo.watchAll('user-1')).called(1);
    });

    test(
      'eggsForIncubationProvider delegates to repository.watchByIncubation',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        container.listen(eggsForIncubationProvider('inc-1'), (_, __) {});
        final eggs = await container.read(
          eggsForIncubationProvider('inc-1').future,
        );

        expect(eggs.single.id, 'e3');
        verify(() => repo.watchByIncubation('inc-1')).called(1);
      },
    );
  });

  group('eggActionsProvider', () {
    test('deleteEgg sets success state', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).deleteEgg('e1');

      final state = container.read(eggActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isTrue);
      verify(() => repo.remove('e1')).called(1);
    });

    test('deleteEgg captures error text on failure', () async {
      when(() => repo.remove('boom')).thenThrow(StateError('delete failed'));
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).deleteEgg('boom');

      final state = container.read(eggActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.error, contains('delete failed'));
    });

    test('reset restores initial state', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).deleteEgg('e1');
      container.read(eggActionsProvider.notifier).reset();

      final state = container.read(eggActionsProvider);
      expect(state, const EggActionsState());
    });
  });
}
