import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
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

  group('NotificationSettingsScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with notifications title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('notifications.title')), findsOneWidget);
    });

    testWidgets('shows SwitchListTile widgets for toggles', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('shows egg turning toggle', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('notifications.egg_turning')), findsOneWidget);
    });

    testWidgets('shows incubation toggle', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('notifications.incubation')), findsOneWidget);
    });

    testWidgets('shows DND section title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // DND section is at the bottom of the ListView and may be outside the
      // default 800x600 test viewport. Scroll down to bring it into view.
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text(l10n('notifications.dnd_title')), findsOneWidget);
    });

    testWidgets('shows sound toggle', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('notifications.sound')), findsOneWidget);
    });
  });
}
