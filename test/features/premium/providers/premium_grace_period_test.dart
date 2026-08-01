import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

Future<ProviderContainer> createContainer({
  Profile? profile,
  DateTime Function()? clock,
}) async {
  final container = ProviderContainer(
    overrides: [
      userProfileProvider.overrideWith((ref) => Stream.value(profile)),
      currentUserIdProvider.overrideWith((ref) => profile?.id ?? 'anon'),
      isAuthenticatedProvider.overrideWith((ref) => true),
      if (clock != null) premiumClockProvider.overrideWithValue(clock),
    ],
  );
  addTearDown(container.dispose);
  container.listen(userProfileProvider, (_, __) {});
  await container.read(userProfileProvider.future);
  return container;
}

void main() {
  group('premiumGracePeriodProvider', () {
    test('returns active when isPremium is true', () async {
      final container = await createContainer(
        profile: const Profile(id: 'u1', email: 'a@b.com', isPremium: true),
      );
      addTearDown(container.dispose);
      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.active,
      );
    });

    test('returns active for admin role', () async {
      final container = await createContainer(
        profile: const Profile(
          id: 'u1',
          email: 'a@b.com',
          isPremium: false,
          role: 'admin',
        ),
      );
      addTearDown(container.dispose);
      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.active,
      );
    });

    test('returns active for founder role', () async {
      final container = await createContainer(
        profile: const Profile(
          id: 'u1',
          email: 'a@b.com',
          isPremium: false,
          role: 'founder',
        ),
      );
      addTearDown(container.dispose);
      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.active,
      );
    });

    test(
      'returns gracePeriod only for a server-provided future grace date',
      () async {
        final now = DateTime.utc(2026, 8, 1);
        final container = await createContainer(
          profile: Profile(
            id: 'u1',
            email: 'a@b.com',
            isPremium: false,
            premiumExpiresAt: now.subtract(const Duration(days: 3)),
            gracePeriodUntil: now.add(const Duration(days: 4)),
          ),
          clock: () => now,
        );
        addTearDown(container.dispose);
        expect(
          container.read(premiumGracePeriodProvider),
          GracePeriodStatus.gracePeriod,
        );
      },
    );

    test('does not fabricate grace from premiumExpiresAt', () async {
      final container = await createContainer(
        profile: Profile(
          id: 'u1',
          email: 'a@b.com',
          isPremium: false,
          premiumExpiresAt: DateTime.now().subtract(const Duration(days: 29)),
        ),
      );
      addTearDown(container.dispose);
      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.free,
      );
    });

    test('returns expired when server grace date has passed', () async {
      final now = DateTime.utc(2026, 8, 1);
      final container = await createContainer(
        profile: Profile(
          id: 'u1',
          email: 'a@b.com',
          isPremium: false,
          gracePeriodUntil: now.subtract(const Duration(seconds: 1)),
        ),
        clock: () => now,
      );
      addTearDown(container.dispose);
      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.expired,
      );
    });

    test('invalidates itself exactly when grace expires', () {
      fakeAsync((async) {
        final now = DateTime.utc(2026, 8, 1);
        final profile = Profile(
          id: 'u1',
          email: 'a@b.com',
          gracePeriodUntil: now.add(const Duration(minutes: 1)),
        );
        final container = ProviderContainer(
          overrides: [
            userProfileProvider.overrideWith((_) => Stream.value(profile)),
            currentUserIdProvider.overrideWithValue('u1'),
            premiumClockProvider.overrideWithValue(
              () => now.add(async.elapsed),
            ),
          ],
        );
        container.listen(userProfileProvider, (_, __) {});
        async.flushMicrotasks();

        expect(
          container.read(premiumGracePeriodProvider),
          GracePeriodStatus.gracePeriod,
        );

        async.elapse(const Duration(minutes: 1));
        async.flushMicrotasks();
        expect(
          container.read(premiumGracePeriodProvider),
          GracePeriodStatus.expired,
        );
        container.dispose();
      });
    });

    test('returns free when no premiumExpiresAt', () async {
      final container = await createContainer(
        profile: const Profile(id: 'u1', email: 'a@b.com', isPremium: false),
      );
      addTearDown(container.dispose);
      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.free,
      );
    });

    test('returns free when profile is null', () async {
      final container = await createContainer(profile: null);
      addTearDown(container.dispose);
      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.free,
      );
    });
  });

  group('effectivePremiumProvider', () {
    test('returns true for active', () {
      final container = ProviderContainer(
        overrides: [
          premiumGracePeriodProvider.overrideWith(
            (ref) => GracePeriodStatus.active,
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(effectivePremiumProvider), true);
    });

    test('returns true for gracePeriod', () {
      final container = ProviderContainer(
        overrides: [
          premiumGracePeriodProvider.overrideWith(
            (ref) => GracePeriodStatus.gracePeriod,
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(effectivePremiumProvider), true);
    });

    test('returns true for an actual profile in grace period', () async {
      final now = DateTime.utc(2026, 8, 1);
      final container = await createContainer(
        profile: Profile(
          id: 'u1',
          email: 'test@test.com',
          isPremium: false,
          premiumExpiresAt: now.subtract(const Duration(days: 20)),
          gracePeriodUntil: now.add(const Duration(days: 10)),
        ),
        clock: () => now,
      );
      addTearDown(container.dispose);
      expect(container.read(effectivePremiumProvider), isTrue);
    });

    test('returns false for expired', () {
      final container = ProviderContainer(
        overrides: [
          premiumGracePeriodProvider.overrideWith(
            (ref) => GracePeriodStatus.expired,
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(effectivePremiumProvider), false);
    });

    test('returns false for an actual profile after grace period', () async {
      final now = DateTime.utc(2026, 8, 1);
      final container = await createContainer(
        profile: Profile(
          id: 'u1',
          email: 'test@test.com',
          isPremium: false,
          gracePeriodUntil: now.subtract(const Duration(days: 1)),
        ),
        clock: () => now,
      );
      addTearDown(container.dispose);
      expect(container.read(effectivePremiumProvider), isFalse);
    });

    test('returns false for free', () {
      final container = ProviderContainer(
        overrides: [
          premiumGracePeriodProvider.overrideWith(
            (ref) => GracePeriodStatus.free,
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(effectivePremiumProvider), false);
    });

    test('returns false for unknown', () {
      final container = ProviderContainer(
        overrides: [
          premiumGracePeriodProvider.overrideWith(
            (ref) => GracePeriodStatus.unknown,
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(effectivePremiumProvider), false);
    });
  });
}
