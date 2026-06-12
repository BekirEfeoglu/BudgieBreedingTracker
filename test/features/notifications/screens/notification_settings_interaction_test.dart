import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/screens/notification_settings_screen.dart';

/// Fake notifier that returns default settings without accessing DAO.
class _FakeToggleNotifier extends NotificationToggleSettingsNotifier {
  @override
  NotificationToggleSettings build() => const NotificationToggleSettings();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWithContainer(void Function(ProviderContainer) onContainer) {
    return ProviderScope(
      overrides: [
        notificationToggleSettingsProvider.overrideWith(
          () => _FakeToggleNotifier(),
        ),
        notificationRateLimiterProvider.overrideWith(
          (ref) => NotificationRateLimiter(),
        ),
      ],
      child: Builder(
        builder: (context) {
          onContainer(ProviderScope.containerOf(context));
          return const MaterialApp(home: NotificationSettingsScreen());
        },
      ),
    );
  }

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        notificationToggleSettingsProvider.overrideWith(
          () => _FakeToggleNotifier(),
        ),
        notificationRateLimiterProvider.overrideWith(
          (ref) => NotificationRateLimiter(),
        ),
      ],
      child: const MaterialApp(home: NotificationSettingsScreen()),
    );
  }

  group('Toggle interaction tests', () {
    testWidgets('tapping egg turning switch updates state', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(createWithContainer((c) => container = c));
      await tester.pumpAndSettle();

      expect(
        container.read(notificationToggleSettingsProvider).eggTurning,
        isTrue,
      );

      final tile = find.widgetWithText(
        SwitchListTile,
        'notifications.egg_turning',
      );
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(
        container.read(notificationToggleSettingsProvider).eggTurning,
        isFalse,
      );
    });

    testWidgets('tapping incubation switch updates state', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(createWithContainer((c) => container = c));
      await tester.pumpAndSettle();

      expect(
        container.read(notificationToggleSettingsProvider).incubation,
        isTrue,
      );

      final tile = find.widgetWithText(
        SwitchListTile,
        'notifications.incubation',
      );
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(
        container.read(notificationToggleSettingsProvider).incubation,
        isFalse,
      );
    });

    testWidgets('tapping sound switch updates state', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(createWithContainer((c) => container = c));
      await tester.pumpAndSettle();

      expect(
        container.read(notificationToggleSettingsProvider).soundEnabled,
        isTrue,
      );

      final tile = find.widgetWithText(SwitchListTile, 'notifications.sound');
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(
        container.read(notificationToggleSettingsProvider).soundEnabled,
        isFalse,
      );
    });

    testWidgets('state updates reflect in UI after toggle', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final tileFinder = find.widgetWithText(
        SwitchListTile,
        'notifications.egg_turning',
      );
      var tile = tester.widget<SwitchListTile>(tileFinder);
      expect(tile.value, isTrue);

      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      tile = tester.widget<SwitchListTile>(tileFinder);
      expect(tile.value, isFalse);
    });
  });

  group('setAll tests', () {
    testWidgets('setAll(false) disables all 4 categories', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(createWithContainer((c) => container = c));
      await tester.pumpAndSettle();

      final notifier = container.read(
        notificationToggleSettingsProvider.notifier,
      );
      await notifier.setAll(false);
      await tester.pumpAndSettle();

      final s = container.read(notificationToggleSettingsProvider);
      expect(s.eggTurning, isFalse);
      expect(s.incubation, isFalse);
      expect(s.chickCare, isFalse);
      expect(s.healthCheck, isFalse);
    });

    testWidgets('setAll(true) enables all 4 categories', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(createWithContainer((c) => container = c));
      await tester.pumpAndSettle();

      final notifier = container.read(
        notificationToggleSettingsProvider.notifier,
      );
      await notifier.setAll(false);
      await tester.pumpAndSettle();
      await notifier.setAll(true);
      await tester.pumpAndSettle();

      final s = container.read(notificationToggleSettingsProvider);
      expect(s.eggTurning, isTrue);
      expect(s.incubation, isTrue);
      expect(s.chickCare, isTrue);
      expect(s.healthCheck, isTrue);
    });
  });

  group('Cleanup section tests', () {
    testWidgets('default cleanup value is 30 days', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(createWithContainer((c) => container = c));
      await tester.pumpAndSettle();

      final s = container.read(notificationToggleSettingsProvider);
      expect(s.cleanupDaysOld, equals(30));
    });

    testWidgets('SegmentedButton selection updates cleanupDaysOld', (
      tester,
    ) async {
      late ProviderContainer container;
      await tester.pumpWidget(createWithContainer((c) => container = c));
      await tester.pumpAndSettle();

      // Scroll down to make the cleanup section visible
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      final segmented = find.byType(SegmentedButton<int>);
      expect(segmented, findsOneWidget);

      // Tap the first segment (value 7) via its descendant InkWell
      final segments = find.descendant(
        of: segmented,
        matching: find.byType(InkWell),
      );
      if (segments.evaluate().isNotEmpty) {
        await tester.tap(segments.first);
        await tester.pumpAndSettle();
      }

      final s = container.read(notificationToggleSettingsProvider);
      expect(s.cleanupDaysOld, equals(7));
    });
  });
}
