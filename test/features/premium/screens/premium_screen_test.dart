import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/screens/premium_screen.dart';

void main() {
  Widget createSubject({bool isPremium = false, String userId = 'test-user'}) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        isPremiumProvider.overrideWithValue(isPremium),
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

      expect(find.text('premium.title'), findsOneWidget);
    });

    testWidgets('shows paywall body for non-premium user', (tester) async {
      await tester.pumpWidget(createSubject(isPremium: false));
      await tester.pumpAndSettle();

      // Paywall contains scrollable content
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('shows already_premium text for premium user', (tester) async {
      await tester.pumpWidget(createSubject(isPremium: true));
      await tester.pumpAndSettle();

      expect(find.text('premium.already_premium'), findsOneWidget);
    });

    testWidgets('paywall shows pricing section', (tester) async {
      await tester.pumpWidget(createSubject(isPremium: false));
      await tester.pumpAndSettle();

      // Paywall body always renders PremiumFeatureListSection
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('guest paywall shows sign-in prompt and legal links', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(isPremium: false, userId: 'anonymous'),
      );
      await tester.pumpAndSettle();

      expect(find.text('premium.account_required_title'), findsOneWidget);
      expect(find.text('settings.privacy_policy'), findsOneWidget);
      expect(find.text('settings.terms (EULA)'), findsOneWidget);
    });
  });
}
