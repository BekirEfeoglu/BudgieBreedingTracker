import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

void main() {
  group('Grace period (30-day window)', () {
    Future<ProviderContainer> createContainer({Profile? profile}) async {
      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          currentUserIdProvider.overrideWith((ref) => profile?.id ?? 'anon'),
          isAuthenticatedProvider.overrideWith((ref) => true),
        ],
      );
      container.listen(userProfileProvider, (_, __) {});
      await container.read(userProfileProvider.future);
      return container;
    }

    test('gracePeriodDays is 30', () {
      expect(AppConstants.gracePeriodDays, 30);
    });

    test('returns gracePeriod when expired 15 days ago', () async {
      final container = await createContainer(
        profile: Profile(
          id: 'u1',
          email: 'test@test.com',
          isPremium: false,
          premiumExpiresAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      );
      addTearDown(container.dispose);

      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.gracePeriod,
      );
    });

    test('returns gracePeriod when expired 29 days ago', () async {
      final container = await createContainer(
        profile: Profile(
          id: 'u1',
          email: 'test@test.com',
          isPremium: false,
          premiumExpiresAt: DateTime.now().subtract(const Duration(days: 29)),
        ),
      );
      addTearDown(container.dispose);

      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.gracePeriod,
      );
    });

    test('returns expired when expired 31 days ago', () async {
      final container = await createContainer(
        profile: Profile(
          id: 'u1',
          email: 'test@test.com',
          isPremium: false,
          premiumExpiresAt: DateTime.now().subtract(const Duration(days: 31)),
        ),
      );
      addTearDown(container.dispose);

      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.expired,
      );
    });

    test('effectivePremiumProvider returns true during grace period', () async {
      final container = await createContainer(
        profile: Profile(
          id: 'u1',
          email: 'test@test.com',
          isPremium: false,
          premiumExpiresAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(effectivePremiumProvider), isTrue);
    });

    test('effectivePremiumProvider returns false after grace period', () async {
      final container = await createContainer(
        profile: Profile(
          id: 'u1',
          email: 'test@test.com',
          isPremium: false,
          premiumExpiresAt: DateTime.now().subtract(const Duration(days: 45)),
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(effectivePremiumProvider), isFalse);
    });
  });
}
