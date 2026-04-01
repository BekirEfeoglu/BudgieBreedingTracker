import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/database/database_provider.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
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
        onPressed: () => performAccountDeletion(
          context,
          ref,
          password: 'test-password',
        ),
        child: const Text('trigger-delete'),
      ),
    );
  }
}

void main() {
  late MockStorageService mockStorage;
  late MockAuthActions mockAuth;
  late MockAppDatabase mockDb;

  setUp(() {
    mockStorage = MockStorageService();
    mockAuth = MockAuthActions();
    mockDb = MockAppDatabase();
    SharedPreferences.setMockInitialValues({});
  });

  void stubAllSuccess() {
    when(() => mockStorage.deleteAllUserFiles(any()))
        .thenAnswer((_) async {});
    when(() => mockAuth.revokeOAuthToken()).thenAnswer((_) async {});
    when(
      () => mockAuth.requestAccountDeletion(
        currentPassword: any(named: 'currentPassword'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockDb.clearAllUserData(any())).thenAnswer((_) async {});
    when(() => mockAuth.signOutAllSessions()).thenAnswer((_) async {});
  }

  Widget buildSubject() {
    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(
          path: '/test',
          builder: (_, __) => const _TestTrigger(),
        ),
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

      verify(() => mockStorage.deleteAllUserFiles('test-user-id')).called(1);
      verify(() => mockAuth.revokeOAuthToken()).called(1);
      verify(
        () => mockAuth.requestAccountDeletion(
          currentPassword: 'test-password',
        ),
      ).called(1);
      verify(() => mockDb.clearAllUserData('test-user-id')).called(1);
      verify(() => mockAuth.signOutAllSessions()).called(1);
    });

    testWidgets('navigates to login after successful deletion', (
      tester,
    ) async {
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

      expect(
        find.text('settings.delete_account_requested'),
        findsOneWidget,
      );
    });

    testWidgets('continues when storage cleanup fails', (tester) async {
      stubAllSuccess();
      when(() => mockStorage.deleteAllUserFiles(any()))
          .thenThrow(Exception('storage error'));

      await pumpLocalizedApp(tester, buildSubject());
      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      // Remaining steps still execute
      verify(
        () => mockAuth.requestAccountDeletion(
          currentPassword: 'test-password',
        ),
      ).called(1);
      verify(() => mockDb.clearAllUserData('test-user-id')).called(1);
      verify(() => mockAuth.signOutAllSessions()).called(1);
      expect(find.text('login-screen'), findsOneWidget);
    });

    testWidgets('continues when OAuth revocation fails', (tester) async {
      stubAllSuccess();
      when(() => mockAuth.revokeOAuthToken())
          .thenThrow(Exception('oauth error'));

      await pumpLocalizedApp(tester, buildSubject());
      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      verify(() => mockDb.clearAllUserData('test-user-id')).called(1);
      verify(() => mockAuth.signOutAllSessions()).called(1);
      expect(find.text('login-screen'), findsOneWidget);
    });

    testWidgets('shows local-only message when server deletion fails', (
      tester,
    ) async {
      stubAllSuccess();
      when(
        () => mockAuth.requestAccountDeletion(
          currentPassword: any(named: 'currentPassword'),
        ),
      ).thenThrow(Exception('server error'));

      await pumpLocalizedApp(tester, buildSubject());
      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      // Local cleanup still executed
      verify(() => mockDb.clearAllUserData('test-user-id')).called(1);
      verify(() => mockAuth.signOutAllSessions()).called(1);

      // Shows local-only message instead of success
      expect(
        find.text('settings.delete_account_local_only'),
        findsOneWidget,
      );
      expect(find.text('login-screen'), findsOneWidget);
    });

    testWidgets('shows error snackbar when DB wipe fails', (tester) async {
      stubAllSuccess();
      when(() => mockDb.clearAllUserData(any()))
          .thenThrow(Exception('db error'));

      await pumpLocalizedApp(tester, buildSubject());
      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      expect(find.text('settings.delete_account_error'), findsOneWidget);
      // Sign-out not reached because DB wipe is not best-effort
      verifyNever(() => mockAuth.signOutAllSessions());
    });

    testWidgets('shows error snackbar when signOut fails', (tester) async {
      stubAllSuccess();
      when(() => mockAuth.signOutAllSessions())
          .thenThrow(Exception('signout error'));

      await pumpLocalizedApp(tester, buildSubject());
      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      expect(find.text('settings.delete_account_error'), findsOneWidget);
    });

    testWidgets('all best-effort steps fail but local cleanup still works', (
      tester,
    ) async {
      stubAllSuccess();
      when(() => mockStorage.deleteAllUserFiles(any()))
          .thenThrow(Exception('storage'));
      when(() => mockAuth.revokeOAuthToken())
          .thenThrow(Exception('oauth'));
      when(
        () => mockAuth.requestAccountDeletion(
          currentPassword: any(named: 'currentPassword'),
        ),
      ).thenThrow(Exception('server'));

      await pumpLocalizedApp(tester, buildSubject());
      await tester.tap(find.text('trigger-delete'));
      await tester.pumpAndSettle();

      // Critical steps still run
      verify(() => mockDb.clearAllUserData('test-user-id')).called(1);
      verify(() => mockAuth.signOutAllSessions()).called(1);
      expect(find.text('login-screen'), findsOneWidget);
    });
  });
}
