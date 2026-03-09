import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/features/profile/widgets/app_preferences_section.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/sync_status_tile.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

class _FakeThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.system;
}

class _FakeAppLocaleNotifier extends AppLocaleNotifier {
  @override
  AppLocale build() => AppLocale.turkish;
}

Future<void> _pump(WidgetTester tester) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: AppPreferencesSection()),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (_, __) => const SizedBox(),
      ),
      GoRoute(path: '/backup', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/premium', builder: (_, __) => const SizedBox()),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(() => _FakeThemeModeNotifier()),
        appLocaleProvider.overrideWith(() => _FakeAppLocaleNotifier()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppPreferencesSection', () {
    testWidgets('renders card container', (tester) async {
      await _pump(tester);

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows theme_mode label', (tester) async {
      await _pump(tester);

      expect(find.text('profile.theme_mode'), findsOneWidget);
    });

    testWidgets('shows SegmentedButton for theme selection', (tester) async {
      await _pump(tester);

      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    });

    testWidgets('shows three theme segments (light, system, dark)', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('profile.theme_light'), findsOneWidget);
      expect(find.text('profile.theme_system'), findsOneWidget);
      expect(find.text('profile.theme_dark'), findsOneWidget);
    });

    testWidgets('shows SyncStatusTile', (tester) async {
      await _pump(tester);

      expect(find.byType(SyncStatusTile), findsOneWidget);
    });

    testWidgets('shows notifications tile', (tester) async {
      await _pump(tester);

      expect(find.text('profile.notifications'), findsOneWidget);
    });

    testWidgets('shows backup export tile', (tester) async {
      await _pump(tester);

      expect(find.text('profile.backup_export'), findsOneWidget);
    });

    testWidgets('shows premium membership tile', (tester) async {
      await _pump(tester);

      expect(find.text('profile.premium_membership'), findsOneWidget);
    });

    testWidgets('shows language tile', (tester) async {
      await _pump(tester);

      expect(find.text('profile.language'), findsOneWidget);
    });

    testWidgets('shows current language native label', (tester) async {
      await _pump(tester);

      // AppLocale.turkish has nativeLabel 'Türkçe'
      expect(find.text('Türkçe'), findsOneWidget);
    });

    testWidgets('has multiple Dividers between tiles', (tester) async {
      await _pump(tester);

      // Multiple dividers exist between sections
      expect(find.byType(Divider), findsAtLeastNWidgets(4));
    });
  });
}
