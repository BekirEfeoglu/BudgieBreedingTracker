import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/subscription_card.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, __) => NoTransitionPage(child: Scaffold(body: child)),
      ),
      GoRoute(
        path: '/premium',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('Premium'))),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('SubscriptionCard', () {
    testWidgets('renders without crashing for null profile', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const SubscriptionCard(profile: null)),
      );

      expect(find.byType(SubscriptionCard), findsOneWidget);
    });

    testWidgets('shows upsell card when profile has no premium', (
      tester,
    ) async {
      const profile = Profile(id: 'u1', email: 'test@test.com');

      await pumpLocalizedApp(
        tester,
        _wrap(const SubscriptionCard(profile: profile)),
      );

      // Upsell card shows 'premium_membership' title
      expect(find.text(l10n('profile.premium_membership')), findsOneWidget);
    });

    testWidgets('shows upsell upgrade button for free user', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const SubscriptionCard(profile: null)),
      );

      expect(find.text(l10n('profile.subscription_upgrade')), findsOneWidget);
    });

    testWidgets('shows upsell benefit rows', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const SubscriptionCard(profile: null)),
      );

      expect(find.text(l10n('profile.subscription_benefit_stats')), findsOneWidget);
      expect(
        find.text(l10n('profile.subscription_benefit_genealogy')),
        findsOneWidget,
      );
      expect(
        find.text(l10n('profile.subscription_benefit_genetics')),
        findsOneWidget,
      );
    });

    testWidgets('shows premium status card for premium user', (tester) async {
      final profile = Profile(
        id: 'u1',
        email: 'test@test.com',
        isPremium: true,
        premiumExpiresAt: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime(2024, 1, 1),
      );

      await pumpLocalizedApp(tester, _wrap(SubscriptionCard(profile: profile)));

      expect(find.text(l10n('profile.subscription_active')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows manage button for premium user', (tester) async {
      final profile = Profile(
        id: 'u1',
        email: 'test@test.com',
        isPremium: true,
        premiumExpiresAt: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime(2024, 1, 1),
      );

      await pumpLocalizedApp(tester, _wrap(SubscriptionCard(profile: profile)));

      expect(find.text(l10n('profile.subscription_manage')), findsOneWidget);
    });

    testWidgets('shows days remaining for premium user with future expiry', (
      tester,
    ) async {
      final profile = Profile(
        id: 'u1',
        email: 'test@test.com',
        isPremium: true,
        premiumExpiresAt: DateTime.now().add(const Duration(days: 15)),
        createdAt: DateTime(2024, 1, 1),
      );

      await pumpLocalizedApp(tester, _wrap(SubscriptionCard(profile: profile)));

      // 'profile.subscription_days_remaining' should be present
      expect(
        find.textContaining(l10nContains('profile.subscription_days_remaining')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('FilledButton navigates to /premium on tap (upsell)', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const SubscriptionCard(profile: null)),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Premium'), findsOneWidget);
    });
  });
}
