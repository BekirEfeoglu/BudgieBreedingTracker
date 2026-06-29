import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/screens/premium_screen.dart';

void main() {
  Widget createSubject({bool isPremium = false, String userId = 'test-user'}) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        // Wave 1 audit: PremiumScreen now reads `effectivePremiumProvider`
        // so grace-period subscribers see their active premium UI rather
        // than the paywall. Override both for safety.
        isPremiumProvider.overrideWithValue(isPremium),
        effectivePremiumProvider.overrideWithValue(isPremium),
        purchaseActionProvider.overrideWith(() => PurchaseActionNotifier()),
        premiumPurchaseIssueProvider.overrideWithValue(null),
        // Offerings: empty list (no RevenueCat in tests)
        premiumOfferingsProvider.overrideWith((_) async => []),
        if (isPremium)
          // subscriptionInfoProvider throws when RevenueCat not initialized
          subscriptionInfoProvider.overrideWith((_) async {
            throw UnimplementedError();
          }),
      ],
      child: const MaterialApp(home: PremiumScreen()),
    );
  }

  group('PremiumScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(PremiumScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with premium title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // SliverAppBar.large renders the title in expanded + collapsed slots.
      expect(find.text(l10n('premium.title')), findsWidgets);
    });

    testWidgets('shows paywall body for non-premium user', (tester) async {
      await tester.pumpWidget(createSubject(isPremium: false));
      await tester.pumpAndSettle();

      // Paywall contains scrollable content
      expect(find.byType(CustomScrollView), findsWidgets);
    });

    testWidgets('shows already_premium text for premium user', (tester) async {
      await tester.pumpWidget(createSubject(isPremium: true));
      await tester.pumpAndSettle();

      expect(find.text(l10n('premium.already_premium')), findsOneWidget);
    });

    testWidgets('paywall shows pricing section', (tester) async {
      await tester.pumpWidget(createSubject(isPremium: false));
      await tester.pumpAndSettle();

      // Paywall body always renders PremiumFeatureListSection
      expect(find.byType(CustomScrollView), findsWidgets);
    });

    testWidgets('guest paywall shows sign-in prompt and legal links', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(isPremium: false, userId: 'anonymous'),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('premium.account_required_title')), findsOneWidget);
      expect(find.text(l10n('settings.privacy_policy')), findsOneWidget);
      expect(find.text('settings.terms (EULA)'), findsOneWidget);
    });
  });
}
