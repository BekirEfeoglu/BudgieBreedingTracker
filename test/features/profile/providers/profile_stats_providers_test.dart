import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  const userId = 'user-1';

  group('isTwoFactorEnabledProvider', () {
    test('delegates to TwoFactorService.isEnabled', () async {
      final service = MockTwoFactorService();
      when(() => service.isEnabled()).thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [twoFactorServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(isTwoFactorEnabledProvider.future),
        completion(isTrue),
      );
      verify(() => service.isEnabled()).called(1);
    });
  });

  group('securityScoreProvider', () {
    test(
      'includes all completed security factors in the total score',
      () async {
        final user = MockUser();
        when(() => user.emailConfirmedAt).thenReturn('2026-01-10T12:00:00Z');

        const profile = Profile(
          id: userId,
          email: 'owner@example.com',
          fullName: 'Owner',
          avatarUrl: 'https://cdn.example.com/avatar.jpg',
          isPremium: true,
        );

        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((_) => user),
            userProfileProvider.overrideWith((_) => Stream.value(profile)),
            isTwoFactorEnabledProvider.overrideWith((_) async => true),
          ],
        );
        addTearDown(container.dispose);

        container.listen(userProfileProvider, (_, __) {});
        await container.read(userProfileProvider.future);
        await container.read(isTwoFactorEnabledProvider.future);

        final score = container.read(securityScoreProvider(userId));

        expect(score.score, 100);
        expect(score.levelKey, 'profile.security_excellent');
        expect(
          score.factors.where((factor) => factor.isCompleted),
          hasLength(5),
        );
      },
    );

    test(
      'keeps only password factor when other factors are incomplete',
      () async {
        final user = MockUser();
        when(() => user.emailConfirmedAt).thenReturn(null);

        const profile = Profile(id: userId, email: 'owner@example.com');

        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((_) => user),
            userProfileProvider.overrideWith((_) => Stream.value(profile)),
            isTwoFactorEnabledProvider.overrideWith((_) async => false),
          ],
        );
        addTearDown(container.dispose);

        container.listen(userProfileProvider, (_, __) {});
        await container.read(userProfileProvider.future);
        await container.read(isTwoFactorEnabledProvider.future);

        final score = container.read(securityScoreProvider(userId));

        expect(score.score, 25);
        expect(score.levelKey, 'profile.security_low');
        expect(score.factors.first.isCompleted, isTrue);
        expect(
          score.factors.skip(1).every((factor) => !factor.isCompleted),
          isTrue,
        );
      },
    );
  });

  group('profileStatsProvider', () {
    test('returns loading while any count stream is unresolved', () {
      final container = ProviderContainer(
        overrides: [
          birdCountProvider(userId).overrideWith((_) => const Stream.empty()),
          activeBreedingCountProvider(
            userId,
          ).overrideWith((_) => Stream.value(2)),
          eggCountProvider(userId).overrideWith((_) => Stream.value(3)),
          chickCountProvider(userId).overrideWith((_) => Stream.value(4)),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(profileStatsProvider(userId)),
        isA<AsyncLoading<ProfileStats>>(),
      );
    });

    test('propagates the first async error', () async {
      final container = ProviderContainer(
        overrides: [
          birdCountProvider(userId).overrideWith(
            (_) => Stream<int>.error(StateError('bird count failed')),
          ),
          activeBreedingCountProvider(
            userId,
          ).overrideWith((_) => Stream.value(2)),
          eggCountProvider(userId).overrideWith((_) => Stream.value(3)),
          chickCountProvider(userId).overrideWith((_) => Stream.value(4)),
        ],
      );
      addTearDown(container.dispose);

      container.listen(profileStatsProvider(userId), (_, __) {});
      await Future<void>.delayed(Duration.zero);
      await expectLater(
        container.read(birdCountProvider(userId).future),
        throwsStateError,
      );

      final value = container.read(profileStatsProvider(userId));
      expect(value.hasError, isTrue);
      expect(value.error, isA<StateError>());
    });

    test('combines all counts into ProfileStats when ready', () async {
      final container = ProviderContainer(
        overrides: [
          birdCountProvider(userId).overrideWith((_) => Stream.value(5)),
          activeBreedingCountProvider(
            userId,
          ).overrideWith((_) => Stream.value(2)),
          eggCountProvider(userId).overrideWith((_) => Stream.value(7)),
          chickCountProvider(userId).overrideWith((_) => Stream.value(4)),
        ],
      );
      addTearDown(container.dispose);

      container.listen(birdCountProvider(userId), (_, __) {});
      await container.read(birdCountProvider(userId).future);
      container.listen(activeBreedingCountProvider(userId), (_, __) {});
      await container.read(activeBreedingCountProvider(userId).future);
      container.listen(eggCountProvider(userId), (_, __) {});
      await container.read(eggCountProvider(userId).future);
      container.listen(chickCountProvider(userId), (_, __) {});
      await container.read(chickCountProvider(userId).future);

      final value = container.read(profileStatsProvider(userId));

      expect(value.hasValue, isTrue);
      expect(
        value.requireValue,
        isA<ProfileStats>()
            .having((stats) => stats.totalBirds, 'totalBirds', 5)
            .having((stats) => stats.totalPairs, 'totalPairs', 2)
            .having((stats) => stats.totalEggs, 'totalEggs', 7)
            .having((stats) => stats.totalChicks, 'totalChicks', 4),
      );
    });
  });

}
