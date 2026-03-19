import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/premium/widgets/pricing_card.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('PricingCard', () {
    testWidgets('displays plan name', (tester) async {
      await pumpWidgetSimple(
        tester,
        PricingCard(
          planName: 'Aylık Plan',
          price: '49,99₺',
          period: 'ay',
          onSubscribe: () {},
        ),
      );

      expect(find.text('Aylık Plan'), findsOneWidget);
    });

    testWidgets('displays price', (tester) async {
      await pumpWidgetSimple(
        tester,
        PricingCard(
          planName: 'Yıllık Plan',
          price: '399,99₺',
          period: 'yıl',
          onSubscribe: () {},
        ),
      );

      expect(find.textContaining('399,99₺', findRichText: true), findsOneWidget);
    });

    testWidgets('displays period', (tester) async {
      await pumpWidgetSimple(
        tester,
        PricingCard(
          planName: 'Plan',
          price: '99₺',
          period: 'ay',
          onSubscribe: () {},
        ),
      );

      expect(find.textContaining('ay', findRichText: true), findsOneWidget);
    });

    testWidgets('renders inside a Card widget', (tester) async {
      await pumpWidgetSimple(
        tester,
        PricingCard(
          planName: 'Plan',
          price: '99₺',
          period: 'ay',
          onSubscribe: () {},
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows badge when provided', (tester) async {
      await pumpWidgetSimple(
        tester,
        PricingCard(
          planName: 'Yıllık',
          price: '399₺',
          period: 'yıl',
          badge: 'En Popüler',
          onSubscribe: () {},
        ),
      );

      expect(find.text('En Popüler'), findsOneWidget);
    });

    testWidgets('shows savings text when provided', (tester) async {
      await pumpWidgetSimple(
        tester,
        PricingCard(
          planName: 'Yıllık',
          price: '399₺',
          period: 'yıl',
          savingsText: '%30 Tasarruf',
          onSubscribe: () {},
        ),
      );

      expect(find.text('%30 Tasarruf'), findsOneWidget);
    });

    testWidgets('onSubscribe callback is invoked when button tapped', (
      tester,
    ) async {
      var subscribed = false;

      await pumpWidgetSimple(
        tester,
        PricingCard(
          planName: 'Premium',
          price: '99₺',
          period: 'ay',
          isHighlighted: true,
          onSubscribe: () => subscribed = true,
        ),
      );

      // Highlighted card uses FilledButton
      final button = find.byWidgetPredicate(
        (w) => w is FilledButton || w is OutlinedButton || w is ElevatedButton,
      );
      expect(button, findsAtLeastNWidgets(1));
      await tester.tap(button.first);
      expect(subscribed, isTrue);
    });

    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        PricingCard(
          planName: 'Plan',
          price: '99₺',
          period: 'ay',
          isLoading: true,
          onSubscribe: () {},
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('highlighted card renders without error', (tester) async {
      await pumpWidgetSimple(
        tester,
        PricingCard(
          planName: 'Premium',
          price: '99₺',
          period: 'ay',
          isHighlighted: true,
          onSubscribe: () {},
        ),
      );

      expect(find.text('Premium'), findsOneWidget);
    });
  });
}
