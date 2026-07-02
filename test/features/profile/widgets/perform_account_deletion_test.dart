import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/data/local/database/database_provider.dart';
import 'package:budgie_breeding_tracker/data/providers/storage_service_provider.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/account_deletion_dialog.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_localization.dart';

class _TestTrigger extends ConsumerWidget {
  const _TestTrigger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () =>
            performAccountDeletion(context, ref, password: 'test-password'),
        child: const Text('trigger-delete'),
      ),
    );
  }
}

void main() {
  late MockStorageService mockStorage;
  late MockAuthActions mockAuth;
  late MockAppDatabase mockDb;
  late MockTwoFactorService mockTwoFactor;

  setUp(() {
    mockStorage = MockStorageService();
    mockAuth = MockAuthActions();
    mockDb = MockAppDatabase();
    mockTwoFactor = MockTwoFactorService();
    SharedPreferences.setMockInitialValues({});
  });

  void stubAllSuccess() {
    when(() => mockStorage.deleteAllUserFiles(any())).thenAnswer((_) async {});
    when(() => mockAuth.revokeOAuthToken()).thenAnswer((_) async {});
    when(
      () => mockAuth.verifyCurrentPassword(
        currentPassword: any(named: 'currentPassword'),
      ),
    ).thenAnswer((_) async {});
    // Default: session already satisfies AAL2 (no MFA enrolled, or already
    // verified this session) — the MFA-challenge retry path has its own
    // dedicated tests.
    when(
      () => mockAuth.requireAal2ForDestructiveAction(),
    ).thenAnswer((_) async {});
    when(
      () => mockAuth.requestAccountDeletionForVerifiedSession(),
    ).thenAnswer((_) async {});
    when(() => mockDb.clearAllUserData(any())).thenAnswer((_) async {});
    when(() => mockAuth.signOutAllSessions()).thenAnswer((_) async {});
  }

  Widget buildSubject() {
    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(path: '/test', builder: (_, __) => const _TestTrigger()),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => const Scaffold(body: Text('login-screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user-id'),
        storageServiceProvider.overrideWithValue(mockStorage),
        authActionsProvider.overrideWithValue(mockAuth),
        appDatabaseProvider.overrideWithValue(mockDb),
        twoFactorServiceProvider.overrideWithValue(mockTwoFactor),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('performAccountDeletion', () {
    testWidgets('calls all deletion steps on success', (tester) async {
      stubAllSuccess();
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      verify(
        () => mockAuth.verifyCurrentPassword(currentPassword: 'test-password'),
      ).called(1);
      verify(() => mockStorage.deleteAllUserFiles('test-user-id')).called(1);
      verify(() => mockAuth.revokeOAuthToken()).called(1);
      verify(
        () => mockAuth.requestAccountDeletionForVerifiedSession(),
      ).called(1);
      verify(() => mockDb.clearAllUserData('test-user-id')).called(1);
      verify(() => mockAuth.signOutAllSessions()).called(1);
    });

    testWidgets('cleans remote storage before deleting auth user', (
      tester,
    ) async {
      stubAllSuccess();
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      verifyInOrder([
        () => mockAuth.verifyCurrentPassword(currentPassword: 'test-password'),
        () => mockAuth.requireAal2ForDestructiveAction(),
        () => mockStorage.deleteAllUserFiles('test-user-id'),
        () => mockAuth.revokeOAuthToken(),
        () => mockAuth.requestAccountDeletionForVerifiedSession(),
        () => mockDb.clearAllUserData('test-user-id'),
      ]);
    });

    testWidgets('navigates to login after successful deletion', (tester) async {
      stubAllSuccess();
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      expect(find.text('login-screen'), findsOneWidget);
    });

    testWidgets('shows success snackbar when server deletion succeeds', (
      tester,
    ) async {
      stubAllSuccess();
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      expect(find.text('settings.delete_account_requested'), findsOneWidget);
    });

    testWidgets('does not delete account when storage cleanup fails', (
      tester,
    ) async {
      stubAllSuccess();
      when(
        () => mockStorage.deleteAllUserFiles(any()),
      ).thenThrow(Exception('storage error'));

      await pumpLocalizedApp(tester, buildSubject());
      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      verifyNever(() => mockAuth.revokeOAuthToken());
      verifyNever(() => mockAuth.requestAccountDeletionForVerifiedSession());
      verifyNever(() => mockDb.clearAllUserData(any()));
      verifyNever(() => mockAuth.signOutAllSessions());
      expect(find.text('settings.delete_account_error'), findsOneWidget);
      expect(find.text('login-screen'), findsNothing);
    });

    testWidgets('continues when OAuth revocation fails', (tester) async {
      stubAllSuccess();
      when(
        () => mockAuth.revokeOAuthToken(),
      ).thenThrow(Exception('oauth error'));

      await pumpLocalizedApp(tester, buildSubject());
      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      verify(() => mockDb.clearAllUserData('test-user-id')).called(1);
      verify(() => mockAuth.signOutAllSessions()).called(1);
      expect(find.text('login-screen'), findsOneWidget);
    });

    testWidgets('does not wipe local data when server deletion fails', (
      tester,
    ) async {
      stubAllSuccess();
      when(
        () => mockAuth.requestAccountDeletionForVerifiedSession(),
      ).thenThrow(Exception('server error'));

      await pumpLocalizedApp(tester, buildSubject());
      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      verifyNever(() => mockDb.clearAllUserData(any()));
      verifyNever(() => mockAuth.signOutAllSessions());

      expect(find.text('settings.delete_account_error'), findsOneWidget);
      expect(find.text('login-screen'), findsNothing);
    });

    testWidgets('does not clear remote storage when password check fails', (
      tester,
    ) async {
      stubAllSuccess();
      when(
        () => mockAuth.verifyCurrentPassword(
          currentPassword: any(named: 'currentPassword'),
        ),
      ).thenThrow(Exception('invalid password'));

      await pumpLocalizedApp(tester, buildSubject());
      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      verifyNever(() => mockStorage.deleteAllUserFiles(any()));
      verifyNever(() => mockAuth.requestAccountDeletionForVerifiedSession());
      verifyNever(() => mockDb.clearAllUserData(any()));
      verifyNever(() => mockAuth.signOutAllSessions());
      expect(find.text('settings.delete_account_error'), findsOneWidget);
      expect(find.text('login-screen'), findsNothing);
    });

    testWidgets('shows error snackbar when DB wipe fails', (tester) async {
      stubAllSuccess();
      when(
        () => mockDb.clearAllUserData(any()),
      ).thenThrow(Exception('db error'));

      await pumpLocalizedApp(tester, buildSubject());
      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      expect(find.text('settings.delete_account_error'), findsOneWidget);
      // Sign-out not reached because DB wipe is not best-effort
      verifyNever(() => mockAuth.signOutAllSessions());
    });

    testWidgets('continues to login when signOut fails (best-effort)', (
      tester,
    ) async {
      stubAllSuccess();
      when(
        () => mockAuth.signOutAllSessions(),
      ).thenThrow(Exception('signout error'));

      await pumpLocalizedApp(tester, buildSubject());
      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      // signOut is best-effort (auth user may already be deleted server-side)
      // so the flow still navigates to login with success snackbar
      expect(find.text('login-screen'), findsOneWidget);
      expect(find.text('settings.delete_account_requested'), findsOneWidget);
    });

    testWidgets('storage failure blocks all later destructive steps', (
      tester,
    ) async {
      stubAllSuccess();
      when(
        () => mockStorage.deleteAllUserFiles(any()),
      ).thenThrow(Exception('storage'));

      await pumpLocalizedApp(tester, buildSubject());
      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      verifyNever(() => mockAuth.revokeOAuthToken());
      verifyNever(() => mockAuth.requestAccountDeletionForVerifiedSession());
      verifyNever(() => mockDb.clearAllUserData(any()));
      verifyNever(() => mockAuth.signOutAllSessions());
      expect(find.text('settings.delete_account_error'), findsOneWidget);
      expect(find.text('login-screen'), findsNothing);
    });
  });

  group('performAccountDeletion — MFA-enrolled session reset to AAL1', () {
    final verifiedFactor = Factor(
      id: 'factor-1',
      friendlyName: 'Authenticator',
      factorType: FactorType.totp,
      status: FactorStatus.verified,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    Future<void> enterOtpCode(WidgetTester tester, String code) async {
      final fields = find.byType(TextFormField);
      for (var i = 0; i < code.length; i++) {
        await tester.enterText(fields.at(i), code[i]);
        await tester.pump();
      }
    }

    testWidgets(
      'shows MFA challenge instead of destroying data when AAL2 is required',
      (tester) async {
        stubAllSuccess();
        when(
          () => mockAuth.requireAal2ForDestructiveAction(),
        ).thenThrow(const MfaAssuranceRequiredException());
        when(
          () => mockTwoFactor.getFactors(),
        ).thenAnswer((_) async => [verifiedFactor]);

        await pumpLocalizedApp(tester, buildSubject());
        await tester.tap(find.text('trigger-delete'));
        await tester.pumpAndSettle();

        // Storage must NOT be touched before the MFA challenge is verified.
        verifyNever(() => mockStorage.deleteAllUserFiles(any()));
        expect(find.text('auth.2fa_verify_title'), findsOneWidget);
      },
    );

    testWidgets(
      'completes deletion after a successful MFA challenge, without '
      're-verifying the password',
      (tester) async {
        stubAllSuccess();
        when(
          () => mockAuth.requireAal2ForDestructiveAction(),
        ).thenThrow(const MfaAssuranceRequiredException());
        when(
          () => mockTwoFactor.getFactors(),
        ).thenAnswer((_) async => [verifiedFactor]);
        when(
          () => mockTwoFactor.challengeAndVerify(
            factorId: 'factor-1',
            code: '123456',
          ),
        ).thenAnswer((_) async => true);

        await pumpLocalizedApp(tester, buildSubject());
        await tester.tap(find.text('trigger-delete'));
        await tester.pumpAndSettle();

        await enterOtpCode(tester, '123456');
        await tester.pumpAndSettle();

        verify(
          () => mockAuth.verifyCurrentPassword(
            currentPassword: 'test-password',
          ),
        ).called(1);
        verify(() => mockStorage.deleteAllUserFiles('test-user-id')).called(1);
        verify(
          () => mockAuth.requestAccountDeletionForVerifiedSession(),
        ).called(1);
        verify(() => mockDb.clearAllUserData('test-user-id')).called(1);
        expect(find.text('login-screen'), findsOneWidget);
        expect(find.text('settings.delete_account_requested'), findsOneWidget);
      },
    );

    testWidgets('does not delete anything when the user cancels the challenge', (
      tester,
    ) async {
      stubAllSuccess();
      when(
        () => mockAuth.requireAal2ForDestructiveAction(),
      ).thenThrow(const MfaAssuranceRequiredException());
      when(
        () => mockTwoFactor.getFactors(),
      ).thenAnswer((_) async => [verifiedFactor]);

      await pumpLocalizedApp(tester, buildSubject());
      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockStorage.deleteAllUserFiles(any()));
      verifyNever(() => mockAuth.requestAccountDeletionForVerifiedSession());
      verifyNever(() => mockDb.clearAllUserData(any()));
      expect(find.text('login-screen'), findsNothing);
    });

    testWidgets(
      'shows an invalid-code error and does not delete when the challenge '
      'code is wrong',
      (tester) async {
        stubAllSuccess();
        when(
          () => mockAuth.requireAal2ForDestructiveAction(),
        ).thenThrow(const MfaAssuranceRequiredException());
        when(
          () => mockTwoFactor.getFactors(),
        ).thenAnswer((_) async => [verifiedFactor]);
        when(
          () => mockTwoFactor.challengeAndVerify(
            factorId: 'factor-1',
            code: '000000',
          ),
        ).thenAnswer((_) async => false);

        await pumpLocalizedApp(tester, buildSubject());
        await tester.tap(find.text('trigger-delete'));
        await tester.pumpAndSettle();

        await enterOtpCode(tester, '000000');
        await tester.pumpAndSettle();

        expect(find.text('auth.2fa_invalid_code'), findsOneWidget);
        verifyNever(() => mockStorage.deleteAllUserFiles(any()));
        verifyNever(() => mockAuth.requestAccountDeletionForVerifiedSession());
      },
    );
  });
}
