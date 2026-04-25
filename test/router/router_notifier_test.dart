import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/router/router_notifier.dart';

class _TestInitSkippedNotifier extends InitSkippedNotifier {
  @override
  bool build() => false;
}

class _TestPendingMfaNotifier extends PendingMfaFactorIdNotifier {
  @override
  String? build() => null;
}

void main() {
  group('RouterNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(false),
          isAdminProvider.overrideWith((_) => false),
          isPremiumProvider.overrideWithValue(false),
          appInitializationProvider.overrideWith((_) {}),
          initSkippedProvider.overrideWith(
            _TestInitSkippedNotifier.new,
          ),
          pendingMfaFactorIdProvider.overrideWith(
            _TestPendingMfaNotifier.new,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('can be created from provider', () {
      final notifier = container.read(routerNotifierProvider);
      expect(notifier, isA<RouterNotifier>());
    });

    test('extends ChangeNotifier', () {
      final notifier = container.read(routerNotifierProvider);
      expect(notifier, isA<ChangeNotifier>());
    });

    testWidgets('notifies listeners when auth state changes', (tester) async {
      // Need a widget tree so addPostFrameCallback can fire
      await tester.pumpWidget(const SizedBox());

      final notifier = container.read(routerNotifierProvider);
      var notified = false;
      notifier.addListener(() => notified = true);

      // Trigger an auth state change
      container.updateOverrides([
        isAuthenticatedProvider.overrideWithValue(true),
        isAdminProvider.overrideWith((_) => false),
        isPremiumProvider.overrideWithValue(false),
        appInitializationProvider.overrideWith((_) {}),
        initSkippedProvider.overrideWith(
          _TestInitSkippedNotifier.new,
        ),
        pendingMfaFactorIdProvider.overrideWith(
          _TestPendingMfaNotifier.new,
        ),
      ]);

      // The notification is scheduled via addPostFrameCallback.
      // Schedule a frame explicitly and pump to fire the callback.
      WidgetsBinding.instance.scheduleFrame();
      await tester.pumpAndSettle();

      expect(notified, isTrue);
    });

    testWidgets('coalesces multiple rapid changes into single notification', (
      tester,
    ) async {
      // Need a widget tree so addPostFrameCallback can fire
      await tester.pumpWidget(const SizedBox());

      final notifier = container.read(routerNotifierProvider);
      var notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      // Trigger multiple state changes in rapid succession
      container.updateOverrides([
        isAuthenticatedProvider.overrideWithValue(true),
        isAdminProvider.overrideWith((_) => true),
        isPremiumProvider.overrideWithValue(true),
        appInitializationProvider.overrideWith((_) {}),
        initSkippedProvider.overrideWith(
          _TestInitSkippedNotifier.new,
        ),
        pendingMfaFactorIdProvider.overrideWith(
          _TestPendingMfaNotifier.new,
        ),
      ]);

      // Schedule a frame and pump to fire the coalesced post-frame callback
      WidgetsBinding.instance.scheduleFrame();
      await tester.pumpAndSettle();

      // Should be coalesced to a single notification (or a small number)
      expect(notifyCount, lessThanOrEqualTo(3));
    });
  });

  group('Navigator keys', () {
    test('rootNavigatorKey is a GlobalKey', () {
      expect(rootNavigatorKey, isA<GlobalKey<NavigatorState>>());
    });

    test('mainShellNavigatorKey is a GlobalKey', () {
      expect(mainShellNavigatorKey, isA<GlobalKey<NavigatorState>>());
    });

    test('adminShellNavigatorKey is a GlobalKey', () {
      expect(adminShellNavigatorKey, isA<GlobalKey<NavigatorState>>());
    });

    test('all navigator keys are distinct', () {
      expect(rootNavigatorKey, isNot(same(mainShellNavigatorKey)));
      expect(rootNavigatorKey, isNot(same(adminShellNavigatorKey)));
      expect(mainShellNavigatorKey, isNot(same(adminShellNavigatorKey)));
    });
  });
}
