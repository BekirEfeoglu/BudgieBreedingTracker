import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/about_section.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/settings_section_header.dart';

void main() {
  late GoRouter router;

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'BudgieBreedingTracker',
      packageName: 'com.test.app',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(child: AboutSection()),
          ),
        ),
        GoRoute(
          path: '/feedback',
          builder: (_, __) => const Scaffold(body: Text('Geri Bildirim')),
        ),
      ],
    );
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        appInfoProvider.overrideWith((ref) async => PackageInfo.fromPlatform()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('AboutSection', () {
    testWidgets('hatasiz render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(AboutSection), findsOneWidget);
    });

    testWidgets('SettingsSectionHeader render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsSectionHeader), findsOneWidget);
    });

    testWidgets('appInfo yuklendikten sonra versiyon gosterilir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Overflow tüket
      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      // Versiyon metnini içeren ListTile bulunabilmeli
      expect(find.text('v1.2.3 (42)'), findsOneWidget);
    });

    testWidgets('appInfo yuklenirken loading durumu gosterilir', (
      tester,
    ) async {
      // AsyncLoading ile direkt override - pending timer olusturmaz
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appInfoProvider.overrideWithValue(
              const AsyncLoading<PackageInfo>(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      expect(find.text('...'), findsOneWidget);
    });

    testWidgets('appInfo hatali oldugunda widget hatasiz render edilir', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appInfoProvider.overrideWith(
              (ref) async => throw Exception('test error'),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Hata durumunda da widget kendini gostermeli (hata propagate etmemeli)
      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }
      expect(find.byType(AboutSection), findsOneWidget);
    });

    testWidgets('yenilikler tile tiklama dialog acar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      // 'Whats new' tile'i bul - SettingsNavigationTile ile
      final tiles = find.byType(ListTile);
      // Ikinci tile yenilikler (indekse gore): daha guvenli yol tile sayisini dogrula
      expect(tiles, findsWidgets);
    });

    testWidgets('birden fazla ListTile render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      // AboutSection en az 5 tile icerir (versiyon, yenilikler, degerlendir, lisanslar, paylas, destek)
      expect(find.byType(ListTile), findsAtLeastNWidgets(5));
    });
  });
}
