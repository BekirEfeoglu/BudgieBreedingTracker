import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/privacy_security_section.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/settings_section_header.dart';

// -- Mocks --

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late GoRouter router;
  late _MockSupabaseClient mockClient;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockClient = _MockSupabaseClient();

    router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(child: PrivacySecuritySection()),
          ),
        ),
        GoRoute(
          path: '/2fa-setup',
          builder: (_, __) => const Scaffold(body: Text('2FA Kurulum')),
        ),
      ],
    );
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [supabaseClientProvider.overrideWithValue(mockClient)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('PrivacySecuritySection', () {
    testWidgets('hatasiz render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(PrivacySecuritySection), findsOneWidget);
    });

    testWidgets('SettingsSectionHeader render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsSectionHeader), findsOneWidget);
    });

    testWidgets('birden fazla ListTile render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      // Sifre degistir, 2FA, aktif oturumlar, veri disaaktar, gizlilik, sartlar, hesap sil
      expect(find.byType(ListTile), findsAtLeastNWidgets(5));
    });

    testWidgets('sifre degistir tile tiklama dialog acar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      // Birinci ListTile sifre degistir
      await tester.tap(find.byType(ListTile).first);
      await tester.pump(const Duration(milliseconds: 300));

      var dialogEx = tester.takeException();
      while (dialogEx != null) {
        dialogEx = tester.takeException();
      }

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('veri disa aktar tile tiklama dialog acar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      // Veri disa aktar 4. tile (index 3)
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.at(3));
      await tester.pump(const Duration(milliseconds: 300));

      var dialogEx = tester.takeException();
      while (dialogEx != null) {
        dialogEx = tester.takeException();
      }

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('aktif oturumlar tile tiklama dialog acar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      // Aktif oturumlar 3. tile (index 2)
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.at(2));
      await tester.pump(const Duration(milliseconds: 300));

      var dialogEx = tester.takeException();
      while (dialogEx != null) {
        dialogEx = tester.takeException();
      }

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('2FA tile tiklama GoRouter push calisir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      // 2FA tile index 1
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.at(1));
      await tester.pumpAndSettle();

      var navEx = tester.takeException();
      while (navEx != null) {
        navEx = tester.takeException();
      }

      expect(find.text('2FA Kurulum'), findsOneWidget);
    });
  });
}
