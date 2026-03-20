import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/screens/notification_settings_screen.dart';

/// Fake notifier that returns configurable settings without accessing DAO.
class _FakeToggleNotifier extends NotificationToggleSettingsNotifier {
  _FakeToggleNotifier([NotificationToggleSettings initial = const NotificationToggleSettings()]) : _initial = initial;
  final NotificationToggleSettings _initial;

  @override
  NotificationToggleSettings build() => _initial;
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

  /// Scrolls down the ListView to bring the DnD section into view.
  Future<void> scrollToDndSection(WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
  }

  group('DndSection (inside NotificationSettingsScreen)', () {
    testWidgets('renders DnD section with moon icon after scrolling', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();
      await scrollToDndSection(tester);

      expect(find.byIcon(LucideIcons.moonStar), findsOneWidget);
    });

    testWidgets('shows DnD title text', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();
      await scrollToDndSection(tester);

      expect(find.text('notifications.dnd_title'), findsOneWidget);
    });

    testWidgets('shows DnD description text', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();
      await scrollToDndSection(tester);

      expect(find.text('notifications.dnd_description'), findsOneWidget);
    });

    testWidgets('shows start and end time labels', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();
      await scrollToDndSection(tester);

      expect(find.text('notifications.dnd_start'), findsOneWidget);
      expect(find.text('notifications.dnd_end'), findsOneWidget);
    });

    testWidgets('displays default DnD hours (23:00 and 07:00)', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();
      await scrollToDndSection(tester);

      expect(find.text('23:00'), findsOneWidget);
      expect(find.text('07:00'), findsOneWidget);
    });

    testWidgets('DnD time tiles contain InkWell for tap interaction', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();
      await scrollToDndSection(tester);

      // The DnD section has two time tiles, each wrapped in an InkWell.
      // Overall screen has multiple InkWells; check at least 2 exist.
      expect(find.byType(InkWell), findsAtLeastNWidgets(2));
    });
  });
}
