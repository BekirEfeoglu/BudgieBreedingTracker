import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

void main() {
  group('premiumGracePeriodProvider', () {
    Future<ProviderContainer> createContainer({Profile? profile}) async {
      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          currentUserIdProvider.overrideWith((ref) => profile?.id ?? 'anon'),
          isAuthenticatedProvider.overrideWith((ref) => true),
        ],
      );
      // Activate the provider so the stream emits and .value is populated.
      container.listen(userProfileProvider, (_, __) {});
      await container.read(userProfileProvider.future);
      return container;
    }

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

    test('returns gracePeriod when expired within 7 days', () async {
      final container = await createContainer(
        profile: Profile(
          id: 'u1',
          email: 'a@b.com',
          isPremium: false,
          premiumExpiresAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      );
      addTearDown(container.dispose);
      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.gracePeriod,
      );
    });

    test('returns expired when expired more than 30 days ago', () async {
      final container = await createContainer(
        profile: Profile(
          id: 'u1',
          email: 'a@b.com',
          isPremium: false,
          premiumExpiresAt: DateTime.now().subtract(const Duration(days: 35)),
        ),
      );
      addTearDown(container.dispose);
      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.expired,
      );
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
