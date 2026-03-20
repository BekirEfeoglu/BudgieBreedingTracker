import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/subscription_info_card.dart';

void main() {
  group('SubscriptionInfoCard', () {
    final baseInfo = SubscriptionInfo(
      isActive: true,
      willRenew: true,
      productId: 'budgie_monthly',
      expirationDate: DateTime(2027, 12, 31),
      isTrial: false,
    );

    Widget createSubject({SubscriptionInfo? info}) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SubscriptionInfoCard(subscriptionInfo: info ?? baseInfo),
          ),
        ),
      );
    }

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(SubscriptionInfoCard), findsOneWidget);
    });

    testWidgets('shows subscription status badge for active subscription', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('premium.active_badge'), findsOneWidget);
      expect(find.text('premium.subscription_active_subtitle'), findsOneWidget);
    });

    testWidgets('shows trial badge for trial subscription', (tester) async {
      const trialInfo = SubscriptionInfo(
        isActive: true,
        isTrial: true,
        willRenew: false,
      );
      await tester.pumpWidget(createSubject(info: trialInfo));
      await tester.pump();

      expect(find.text('premium.trial_active_badge'), findsOneWidget);
      expect(find.text('premium.trial_subtitle'), findsOneWidget);
    });

    testWidgets('shows plan name for monthly product', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('premium.current_plan'), findsOneWidget);
      expect(find.text('premium.plan_monthly'), findsOneWidget);
    });

    testWidgets('shows plan name for yearly product', (tester) async {
      const yearlyInfo = SubscriptionInfo(
        isActive: true,
        productId: 'budgie_yearly',
        willRenew: true,
      );
      await tester.pumpWidget(createSubject(info: yearlyInfo));
      await tester.pump();

      expect(find.text('premium.plan_yearly'), findsOneWidget);
    });

    testWidgets('shows plan name for lifetime product', (tester) async {
      const lifetimeInfo = SubscriptionInfo(
        isActive: true,
        productId: 'budgie_lifetime',
        willRenew: false,
      );
      await tester.pumpWidget(createSubject(info: lifetimeInfo));
      await tester.pump();

      expect(find.text('premium.plan_lifetime'), findsOneWidget);
    });

    testWidgets('shows expiry date when expirationDate is provided', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('premium.expires_at'), findsOneWidget);
      expect(find.text('31.12.2027'), findsOneWidget);
    });

    testWidgets('shows remaining days for future expiration', (tester) async {
      final futureInfo = SubscriptionInfo(
        isActive: true,
        expirationDate: DateTime.now().add(const Duration(days: 30)),
        willRenew: true,
      );
      await tester.pumpWidget(createSubject(info: futureInfo));
      await tester.pump();

      expect(find.text('premium.remaining_days'), findsOneWidget);
    });

    testWidgets('shows expired text when expiration is in the past', (
      tester,
    ) async {
      final pastInfo = SubscriptionInfo(
        isActive: true,
        expirationDate: DateTime.now().subtract(const Duration(days: 5)),
        willRenew: false,
      );
      await tester.pumpWidget(createSubject(info: pastInfo));
      await tester.pump();

      expect(find.text('premium.expired'), findsOneWidget);
    });

    testWidgets('shows will_renew yes for renewing subscription', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('premium.will_renew'), findsOneWidget);
      expect(find.text('common.yes'), findsOneWidget);
    });

    testWidgets('shows will_renew no for non-renewing subscription', (
      tester,
    ) async {
      const noRenewInfo = SubscriptionInfo(
        isActive: true,
        willRenew: false,
        productId: 'budgie_monthly',
        isTrial: false,
      );
      await tester.pumpWidget(createSubject(info: noRenewInfo));
      await tester.pump();

      expect(find.text('premium.will_renew'), findsOneWidget);
      expect(find.text('common.no'), findsOneWidget);
    });

    testWidgets('does not show current_plan when productId is null', (
      tester,
    ) async {
      const noProductInfo = SubscriptionInfo(
        isActive: true,
        willRenew: false,
        isTrial: false,
      );
      await tester.pumpWidget(createSubject(info: noProductInfo));
      await tester.pump();

      expect(find.text('premium.current_plan'), findsNothing);
    });

    testWidgets('does not show expiry fields when expirationDate is null', (
      tester,
    ) async {
      const noExpiryInfo = SubscriptionInfo(
        isActive: true,
        productId: 'budgie_lifetime',
        willRenew: false,
      );
      await tester.pumpWidget(createSubject(info: noExpiryInfo));
      await tester.pump();

      expect(find.text('premium.expires_at'), findsNothing);
      expect(find.text('premium.remaining_days'), findsNothing);
    });

    testWidgets('renders a Card widget', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
    });
  });
}
