import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/features/chicks/providers/chick_form_providers.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/mocks.dart';

Chick _chick({String id = 'chick-1'}) {
  return Chick(id: id, userId: 'user-1', hatchDate: DateTime(2025, 3, 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockChickRepository mockChickRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockChickRepo = MockChickRepository();
    registerFallbackValue(_chick());
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [chickRepositoryProvider.overrideWithValue(mockChickRepo)],
    );
  }

  group('ChickFormState', () {
    test('default state is not loading, no error, not success', () {
      const state = ChickFormState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates isLoading', () {
      const state = ChickFormState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
    });

    test('copyWith clears error when null is passed', () {
      const state = ChickFormState(error: 'Some error');
      final updated = state.copyWith(error: null);
      expect(updated.error, isNull);
    });

    test('copyWith can set isSuccess', () {
      const state = ChickFormState();
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isSuccess, isTrue);
    });
  });

  group('ChickFormNotifier.createChick', () {
    test('sets isSuccess after successful save', () async {
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .createChick(userId: 'user-1', hatchDate: DateTime(2025, 3, 1));

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('saves chick with provided name', () async {
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .createChick(
            userId: 'user-1',
            name: 'Mavis',
            gender: BirdGender.female,
            hatchDate: DateTime(2025, 3, 1),
          );

      final captured = verify(() => mockChickRepo.save(captureAny())).captured;
      final savedChick = captured.first as Chick;
      expect(savedChick.name, 'Mavis');
      expect(savedChick.gender, BirdGender.female);
      expect(savedChick.userId, 'user-1');
    });

    test('sets error state when repo throws', () async {
      when(() => mockChickRepo.save(any())).thenThrow(Exception('DB error'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .createChick(userId: 'user-1', hatchDate: DateTime(2025, 3, 1));

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('sets isLoading to false even when inner scheduler throws', () async {
      // Inner try-catch catches scheduler errors silently;
      // the outer catch only fires if repo.save throws.
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .createChick(userId: 'user-1', hatchDate: DateTime(2025, 3, 1));

      final state = container.read(chickFormStateProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isTrue);
    });
  });

  group('ChickFormNotifier.updateChick', () {
    test('sets isSuccess after saving updated chick', () async {
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .updateChick(_chick());

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('calls save with updated timestamp', () async {
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      final before = DateTime.now();
      await container
          .read(chickFormStateProvider.notifier)
          .updateChick(_chick());
      final after = DateTime.now();

      final captured = verify(() => mockChickRepo.save(captureAny())).captured;
      final savedChick = captured.first as Chick;
      expect(
        savedChick.updatedAt!.isAfter(before) ||
            savedChick.updatedAt!.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        savedChick.updatedAt!.isBefore(after) ||
            savedChick.updatedAt!.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('sets error when repo throws', () async {
      when(() => mockChickRepo.save(any())).thenThrow(Exception('Save failed'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .updateChick(_chick());

      final state = container.read(chickFormStateProvider);
      expect(state.error, isNotNull);
      expect(state.isSuccess, isFalse);
    });
  });

  group('ChickFormNotifier.deleteChick', () {
    test('sets isSuccess after removing chick', () async {
      when(() => mockChickRepo.remove(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .deleteChick('chick-1');

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('calls remove with correct id', () async {
      when(() => mockChickRepo.remove(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .deleteChick('chick-99');

      verify(() => mockChickRepo.remove('chick-99')).called(1);
    });

    test('sets error when remove throws', () async {
      when(
        () => mockChickRepo.remove(any()),
      ).thenThrow(Exception('Delete error'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .deleteChick('chick-1');

      final state = container.read(chickFormStateProvider);
      expect(state.error, isNotNull);
      expect(state.isSuccess, isFalse);
    });
  });

  group('ChickFormNotifier.markAsWeaned', () {
    test('updates wean date and sets isSuccess', () async {
      final chick = _chick();
      when(
        () => mockChickRepo.getById('chick-1'),
      ).thenAnswer((_) async => chick);
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      final weanDate = DateTime(2025, 4, 1);
      await container
          .read(chickFormStateProvider.notifier)
          .markAsWeaned('chick-1', weanDate: weanDate);

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isTrue);

      final captured = verify(() => mockChickRepo.save(captureAny())).captured;
      final savedChick = captured.first as Chick;
      expect(savedChick.weanDate, weanDate);
    });

    test('sets isSuccess even when chick not found (no-op)', () async {
      when(() => mockChickRepo.getById(any())).thenAnswer((_) async => null);

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .markAsWeaned('missing-chick');

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isTrue);
    });
  });

  group('ChickFormNotifier.markAsDeceased', () {
    test('updates health status and sets isSuccess', () async {
      final chick = _chick();
      when(
        () => mockChickRepo.getById('chick-1'),
      ).thenAnswer((_) async => chick);
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .markAsDeceased('chick-1');

      final captured = verify(() => mockChickRepo.save(captureAny())).captured;
      final savedChick = captured.first as Chick;
      expect(savedChick.healthStatus, ChickHealthStatus.deceased);
    });
  });

  group('ChickFormNotifier.reset', () {
    test('resets state to default after an operation', () async {
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .updateChick(_chick());

      expect(container.read(chickFormStateProvider).isSuccess, isTrue);

      container.read(chickFormStateProvider.notifier).reset();

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });
  });
}
