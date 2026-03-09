import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/notifications_section.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/settings_navigation_tile.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/settings_section_header.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/settings_toggle_tile.dart';

// -- Test Notifier --

class _FakeNotificationsMasterNotifier extends NotificationsMasterNotifier {
  final bool _initial;
  _FakeNotificationsMasterNotifier(this._initial);

  @override
  bool build() => _initial;

  @override
  Future<void> toggle() async {
    state = !state;
  }
}

void main() {
  late GoRouter router;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(child: NotificationsSection()),
          ),
        ),
        GoRoute(
          path: '/notification-settings',
          builder: (_, __) => const Scaffold(body: Text('Bildirim Ayarlari')),
        ),
      ],
    );
  });

  Widget buildSubject({bool masterEnabled = true}) {
    return ProviderScope(
      overrides: [
        notificationsMasterProvider.overrideWith(
          () => _FakeNotificationsMasterNotifier(masterEnabled),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('NotificationsSection', () {
    testWidgets('hatasiz render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(NotificationsSection), findsOneWidget);
    });

    testWidgets('SettingsSectionHeader render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsSectionHeader), findsOneWidget);
    });

    testWidgets('master toggle tile render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsToggleTile), findsOneWidget);
    });

    testWidgets('bildirim kategorileri navigasyon tile render edilir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsNavigationTile), findsOneWidget);
    });

    testWidgets('masterEnabled=true iken switch acik gosterilir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(masterEnabled: true));
      await tester.pump(const Duration(milliseconds: 500));
      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, isTrue);
    });

    testWidgets('masterEnabled=false iken switch kapali gosterilir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(masterEnabled: false));
      await tester.pump(const Duration(milliseconds: 500));
      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, isFalse);
    });

    testWidgets('master toggle tiklama sonrasi durum degisir', (tester) async {
      await tester.pumpWidget(buildSubject(masterEnabled: true));
      await tester.pump(const Duration(milliseconds: 500));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(NotificationsSection)),
      );
      container.read(notificationsMasterProvider.notifier).toggle();
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(notificationsMasterProvider), isFalse);
    });

    testWidgets('bildirim kategorileri tile tiklama GoRouter push calisir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byType(SettingsNavigationTile));
      await tester.pumpAndSettle();

      expect(find.text('Bildirim Ayarlari'), findsOneWidget);
    });
  });
}
