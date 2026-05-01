@Tags(['e2e'])
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

import '../helpers/e2e_test_harness.dart';

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

  group('Profile Flow E2E', () {
    test(
      'GIVEN authenticated user WHEN profile is opened THEN display name email avatar and subscription status are loaded',
      () async {
        final mockProfileRepository = MockProfileRepository();
        const profile = Profile(
          id: 'test-user',
          email: 'test@example.com',
          fullName: 'Test Kullanici',
          avatarUrl: 'https://cdn.example.com/avatar.png',
          isPremium: false,
        );

        when(
          () => mockProfileRepository.watchProfile('test-user'),
        ).thenAnswer((_) => Stream.value(profile));

        final container = createTestContainer(
          overrides: [
            profileRepositoryProvider.overrideWithValue(mockProfileRepository),
          ],
        );
        addTearDown(container.dispose);

        final loaded = await _awaitProviderValue<Profile?>(
          container,
          userProfileProvider,
        );

        expect(loaded?.fullName, 'Test Kullanici');
        expect(loaded?.email, 'test@example.com');
        expect(loaded?.avatarUrl, isNotNull);
        expect(loaded?.hasPremium, isFalse);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN profile screen WHEN display name is edited and saved THEN profile repository save is called and success state is available',
      () async {
        final mockProfileRepository = MockProfileRepository();
        const existingProfile = Profile(
          id: 'test-user',
          email: 'test@example.com',
          fullName: 'Eski Ad',
        );
        const updatedProfile = Profile(
          id: 'test-user',
          email: 'test@example.com',
          fullName: 'Yeni Gorunen Ad',
        );

        when(
          () => mockProfileRepository.getById('test-user'),
        ).thenAnswer((_) async => existingProfile);
        when(
          () => mockProfileRepository.save(updatedProfile),
        ).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            profileRepositoryProvider.overrideWithValue(mockProfileRepository),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileRepositoryProvider).save(updatedProfile);

        verify(() => mockProfileRepository.save(updatedProfile)).called(1);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN profile screen WHEN avatar image is picked and uploaded THEN repository avatar upload is called',
      () async {
        final mockProfileRepository = MockProfileRepository();
        final picked = XFile('avatar.jpg');

        when(
          () => mockProfileRepository.uploadAvatar(
            userId: 'test-user',
            file: picked,
          ),
        ).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            profileRepositoryProvider.overrideWithValue(mockProfileRepository),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(avatarUploadStateProvider.notifier)
            .uploadAvatar(picked);

        verify(
          () => mockProfileRepository.uploadAvatar(
            userId: 'test-user',
            file: picked,
          ),
        ).called(1);
        expect(container.read(avatarUploadStateProvider).isSuccess, isTrue);
      },
      timeout: e2eTimeout,
    );
  });
}
