import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/premium_paywall_sections.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

Widget _wrapWithProviders(
  Widget child, {
  String userId = 'test-user',
}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      purchaseActionProvider.overrideWith(() => PurchaseActionNotifier()),
    ],
    child: _wrap(child),
  );
}

void main() {
  group('PremiumRestoreSection', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumRestoreSection()),
      );
      await tester.pump();

      expect(find.byType(PremiumRestoreSection), findsOneWidget);
    });

    testWidgets('shows restore info text for logged-in user', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumRestoreSection()),
      );
      await tester.pump();

      expect(find.text('premium.restore_info'), findsOneWidget);
    });

    testWidgets('shows restore purchases button for logged-in user', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumRestoreSection()),
      );
      await tester.pump();

      expect(find.text('premium.restore_purchases'), findsOneWidget);
    });

    testWidgets('shows rotate icon for logged-in user', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumRestoreSection()),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.icon == LucideIcons.rotateCcw &&
              widget.size == 16,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows sign-in text for anonymous user', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const PremiumRestoreSection(),
          userId: 'anonymous',
        ),
      );
      await tester.pump();

      expect(find.text('premium.sign_in_to_purchase'), findsOneWidget);
    });

    testWidgets('shows login button for anonymous user', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const PremiumRestoreSection(),
          userId: 'anonymous',
        ),
      );
      await tester.pump();

      expect(find.text('auth.login'), findsOneWidget);
    });

    testWidgets('shows logIn icon for anonymous user', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const PremiumRestoreSection(),
          userId: 'anonymous',
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.icon == LucideIcons.logIn &&
              widget.size == 16,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows divider', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumRestoreSection()),
      );
      await tester.pump();

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('restore button is a TextButton.icon', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumRestoreSection()),
      );
      await tester.pump();

      expect(find.byType(TextButton), findsAtLeastNWidgets(1));
    });
  });
}
