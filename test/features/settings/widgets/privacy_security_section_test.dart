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
import 'package:budgie_breeding_tracker/shared/widgets/profile_account.dart'
    show PasswordChangeForm;
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import '../../../helpers/test_localization.dart';

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
      await pumpLocalizedApp(tester, buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PrivacySecuritySection), findsOneWidget);
    });

    testWidgets('SettingsSectionHeader render edilir', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsSectionHeader), findsOneWidget);
    });

    testWidgets('birden fazla ListTile render edilir', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // Sifre degistir, 2FA, aktif oturumlar, veri disaaktar, gizlilik, sartlar, hesap sil
      expect(find.byType(ListTile), findsAtLeastNWidgets(5));
    });

    testWidgets('sifre degistir tile tiklama sifre degistirme sayfasi acar', (
      tester,
    ) async {
      await pumpLocalizedApp(tester, buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // Tap by tile title, not index — the read-receipts SwitchListTile shifts
      // positional finders (this list already needed one index-fix commit).
      await tester.tap(
        find.widgetWithText(ListTile, l10n('settings.change_password')),
      );
      await tester.pumpAndSettle();

      // Delegates to the shared MFA-aware password-change sheet, which renders
      // a PasswordChangeForm (previously a bespoke Dialog that swallowed the
      // MFA re-auth exception for 2FA users).
      expect(find.byType(PasswordChangeForm), findsOneWidget);
    });

    testWidgets('veri disa aktar tile tiklama dialog acar', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(
        find.widgetWithText(ListTile, l10n('settings.export_personal_data')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('aktif oturumlar tile tiklama dialog acar', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(
        find.widgetWithText(ListTile, l10n('settings.active_sessions')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('2FA tile tiklama GoRouter push calisir', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(
        find.widgetWithText(ListTile, l10n('settings.two_factor_auth')),
      );
      await tester.pumpAndSettle();

      expect(find.text('2FA Kurulum'), findsOneWidget);
    });
  });
}
