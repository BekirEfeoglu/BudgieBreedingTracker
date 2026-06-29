import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_settings_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/screens/settings_screen.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/about_section.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/accessibility_section.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/data_storage_section.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/display_section.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/language_section.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/notifications_section.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/privacy_security_section.dart';

import '../../../helpers/test_settings_notifiers.dart';
import '../../../helpers/mocks.dart';

class _TestNotificationToggleSettingsNotifier
    extends NotificationToggleSettingsNotifier {
  @override
  NotificationToggleSettings build() => const NotificationToggleSettings();

  @override
  Future<void> setAll(bool value) async {
    state = state.copyWith(
      eggTurning: value,
      incubation: value,
      chickCare: value,
      healthCheck: value,
    );
  }
}

void main() {
  late GoRouter router;
  late MockSyncOrchestrator mockOrchestrator;

  setUp(() {
    mockOrchestrator = MockSyncOrchestrator();
    router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(
          path: '/backup',
          builder: (_, __) => const Scaffold(body: Text('Backup')),
        ),
        GoRoute(
          path: '/notification-settings',
          builder: (_, __) => const Scaffold(body: Text('NotifSettings')),
        ),
        GoRoute(
          path: '/2fa-setup',
          builder: (_, __) => const Scaffold(body: Text('2FA')),
        ),
        GoRoute(
          path: '/feedback',
          builder: (_, __) => const Scaffold(body: Text('Feedback')),
        ),
      ],
    );
  });

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(TestThemeModeNotifier.new),
        fontScaleProvider.overrideWith(TestFontScaleNotifier.new),
        appLocaleProvider.overrideWith(TestAppLocaleNotifier.new),
        notificationToggleSettingsProvider.overrideWith(
          _TestNotificationToggleSettingsNotifier.new,
        ),
        compactViewProvider.overrideWith(TestCompactViewNotifier.new),
        autoSyncProvider.overrideWith(TestAutoSyncNotifier.new),
        hapticFeedbackProvider.overrideWith(TestHapticFeedbackNotifier.new),
        reduceAnimationsProvider.overrideWith(TestReduceAnimationsNotifier.new),
        dateFormatProvider.overrideWith(TestDateFormatNotifier.new),
        lastSyncTimeProvider.overrideWith(TestLastSyncTimeNotifier.new),
        syncOrchestratorProvider.overrideWithValue(mockOrchestrator),
        cacheSizeProvider.overrideWith((ref) => Future.value(2048)),
        appInfoProvider.overrideWith(
          (ref) => Future.value(
            PackageInfo(
              appName: 'Test',
              packageName: 'com.test',
              version: '1.0.2',
              buildNumber: '1',
            ),
          ),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('SettingsScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('shows settings title in AppBar', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // SliverAppBar.large renders the title in both its expanded and
      // collapsed slots, so more than one match is expected.
      expect(find.text(l10n('settings.title')), findsWidgets);
    });

    testWidgets('shows all setting sections', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // Sections are lazy SliverList children; some may be off-screen.
      expect(find.byType(CustomScrollView), findsOneWidget);

      // Visible sections (top of list)
      expect(find.byType(DisplaySection), findsOneWidget);
      expect(find.byType(LanguageSection), findsOneWidget);
      expect(find.byType(AccessibilitySection), findsOneWidget);

      // Scroll each remaining section into view. `scrollUntilVisible` is
      // robust to the SliverAppBar.large collapse consuming scroll extent.
      final scrollable = find.byType(Scrollable).first;
      for (final section in [
        find.byType(NotificationsSection),
        find.byType(DataStorageSection),
        find.byType(PrivacySecuritySection),
        find.byType(AboutSection),
      ]) {
        await tester.scrollUntilVisible(section, 300, scrollable: scrollable);
        expect(section, findsOneWidget);
      }
    });

    testWidgets('renders as a CustomScrollView', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('scrolls through all sections without error', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      final listFinder = find.byType(CustomScrollView);
      await tester.fling(listFinder, const Offset(0, -2000), 3000);
      await tester.pumpAndSettle();
      await tester.fling(listFinder, const Offset(0, 2000), 3000);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
