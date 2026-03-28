import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/subscription_info_card.dart';

void main() {
  group('SubscriptionInfoCard', () {
    final baseInfo = SubscriptionInfo(
      isActive: true,
      willRenew: true,
      productId: 'budgie_semi_annual',
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

    testWidgets('shows active_badge text for non-trial subscription', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('premium.active_badge'), findsOneWidget);
    });

    testWidgets('shows trial_active_badge text for trial subscription', (
      tester,
    ) async {
      const trialInfo = SubscriptionInfo(
        isActive: true,
        isTrial: true,
        willRenew: false,
      );
      await tester.pumpWidget(createSubject(info: trialInfo));
      await tester.pump();

      expect(find.text('premium.trial_active_badge'), findsOneWidget);
    });

    testWidgets('shows will_renew label', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('premium.will_renew'), findsOneWidget);
    });

    testWidgets('shows current_plan label when productId is provided', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('premium.current_plan'), findsOneWidget);
    });

    testWidgets('shows plan_semi_annual for semi-annual product id', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('premium.plan_semi_annual'), findsOneWidget);
    });

    testWidgets('shows plan_yearly for yearly product id', (tester) async {
      const yearlyInfo = SubscriptionInfo(
        isActive: true,
        productId: 'budgie_yearly',
        willRenew: true,
      );
      await tester.pumpWidget(createSubject(info: yearlyInfo));
      await tester.pump();

      expect(find.text('premium.plan_yearly'), findsOneWidget);
    });

    testWidgets('shows expires_at label when expirationDate is provided', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('premium.expires_at'), findsOneWidget);
    });

    testWidgets('shows formatted expiration date', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // Date format: DD.MM.YYYY
      expect(find.text('31.12.2027'), findsOneWidget);
    });

    testWidgets('shows remaining_days when not expired', (tester) async {
      final futureInfo = SubscriptionInfo(
        isActive: true,
        expirationDate: DateTime.now().add(const Duration(days: 30)),
        willRenew: true,
      );
      await tester.pumpWidget(createSubject(info: futureInfo));
      await tester.pump();

      expect(find.text('premium.remaining_days'), findsOneWidget);
    });

    testWidgets('shows Card widget', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('does not show current_plan label when productId is null', (
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
  });
}
