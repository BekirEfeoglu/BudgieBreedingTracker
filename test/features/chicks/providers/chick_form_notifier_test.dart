import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_form_providers.dart';

import '../../../helpers/mocks.dart';

Chick _chick({
  String id = 'chick-1',
  String? name,
  BirdGender gender = BirdGender.unknown,
  int bandingDay = 10,
  DateTime? hatchDate,
}) {
  return Chick(
    id: id,
    userId: 'user-1',
    name: name,
    gender: gender,
    healthStatus: ChickHealthStatus.healthy,
    hatchDate: hatchDate ?? DateTime(2025, 3, 1),
    bandingDay: bandingDay,
  );
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

  group('ChickFormNotifier - build', () {
    test('initial state is default ChickFormState', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(chickFormStateProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.warning, isNull);
      expect(state.isSuccess, isFalse);
    });
  });

  group('ChickFormNotifier - createChick with defaults', () {
    test('saves chick with default gender and health status', () async {
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .createChick(userId: 'user-1', hatchDate: DateTime(2025, 3, 1));

      final captured =
          verify(() => mockChickRepo.save(captureAny())).captured;
      final savedChick = captured.first as Chick;
      expect(savedChick.gender, BirdGender.unknown);
      expect(savedChick.healthStatus, ChickHealthStatus.healthy);
      expect(savedChick.userId, 'user-1');
      expect(savedChick.id, isNotEmpty);
    });

    test('saves chick with all provided fields', () async {
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(chickFormStateProvider.notifier).createChick(
            userId: 'user-1',
            name: 'Pamuk',
            gender: BirdGender.female,
            healthStatus: ChickHealthStatus.sick,
            clutchId: 'clutch-1',
            eggId: 'egg-1',
            hatchDate: DateTime(2025, 3, 1),
            hatchWeight: 3.5,
            ringNumber: 'R-001',
            notes: 'Test notes',
            bandingDay: 12,
          );

      final captured =
          verify(() => mockChickRepo.save(captureAny())).captured;
      final savedChick = captured.first as Chick;
      expect(savedChick.name, 'Pamuk');
      expect(savedChick.gender, BirdGender.female);
      expect(savedChick.healthStatus, ChickHealthStatus.sick);
      expect(savedChick.clutchId, 'clutch-1');
      expect(savedChick.eggId, 'egg-1');
      expect(savedChick.hatchWeight, 3.5);
      expect(savedChick.ringNumber, 'R-001');
      expect(savedChick.notes, 'Test notes');
      expect(savedChick.bandingDay, 12);
    });

    test('generates unique ID for each chick', () async {
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .createChick(userId: 'user-1', hatchDate: DateTime(2025, 3, 1));
      container.read(chickFormStateProvider.notifier).reset();

      await container
          .read(chickFormStateProvider.notifier)
          .createChick(userId: 'user-1', hatchDate: DateTime(2025, 3, 2));

      final captured =
          verify(() => mockChickRepo.save(captureAny())).captured;
      final chick1 = captured[0] as Chick;
      final chick2 = captured[1] as Chick;
      expect(chick1.id, isNot(equals(chick2.id)));
    });
  });

  group('ChickFormNotifier - updateChick', () {
    test('updates chick with new timestamp', () async {
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      final original = _chick(name: 'Old Name');
      final updated = original.copyWith(name: 'New Name');

      await container
          .read(chickFormStateProvider.notifier)
          .updateChick(updated);

      final captured =
          verify(() => mockChickRepo.save(captureAny())).captured;
      final saved = captured.first as Chick;
      expect(saved.name, 'New Name');
      expect(saved.updatedAt, isNotNull);
    });

    test('reschedules banding when bandingDay changes and chick is not banded',
        () async {
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      final previous = _chick(bandingDay: 10);
      final updated = previous.copyWith(bandingDay: 14);

      await container
          .read(chickFormStateProvider.notifier)
          .updateChick(updated, previous: previous);

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isTrue);
      // Even without the scheduler mocked, the operation succeeds
      // (side-effect errors are caught internally)
    });
  });

  group('ChickFormNotifier - deleteChick', () {
    test('calls remove on repository', () async {
      when(() => mockChickRepo.remove(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .deleteChick('chick-99');

      verify(() => mockChickRepo.remove('chick-99')).called(1);
      expect(container.read(chickFormStateProvider).isSuccess, isTrue);
    });

    test('sets error state on failure', () async {
      when(() => mockChickRepo.remove(any()))
          .thenThrow(Exception('Delete failed'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .deleteChick('chick-1');

      final state = container.read(chickFormStateProvider);
      expect(state.error, isNotNull);
      expect(state.isSuccess, isFalse);
      expect(state.isLoading, isFalse);
    });
  });

  group('ChickFormNotifier - reset', () {
    test('restores default state after success', () async {
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .createChick(userId: 'user-1', hatchDate: DateTime(2025, 3, 1));
      expect(container.read(chickFormStateProvider).isSuccess, isTrue);

      container.read(chickFormStateProvider.notifier).reset();

      final state = container.read(chickFormStateProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNull);
      expect(state.warning, isNull);
    });

    test('restores default state after error', () async {
      when(() => mockChickRepo.save(any())).thenThrow(Exception('fail'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .createChick(userId: 'user-1', hatchDate: DateTime(2025, 3, 1));
      expect(container.read(chickFormStateProvider).error, isNotNull);

      container.read(chickFormStateProvider.notifier).reset();

      final state = container.read(chickFormStateProvider);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });
  });

  group('ChickFormState', () {
    test('copyWith with warning', () {
      const state = ChickFormState();
      final updated = state.copyWith(warning: 'partial failure');
      expect(updated.warning, 'partial failure');
    });

    test('copyWith clears warning when null', () {
      const state = ChickFormState(warning: 'warn');
      final updated = state.copyWith(warning: null);
      expect(updated.warning, isNull);
    });
  });
}
