import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/providers/edge_function_provider.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/two_factor_verify_screen.dart';
import 'package:budgie_breeding_tracker/router/post_auth_destination_store.dart';

import '../../../helpers/e2e_test_harness.dart';

class _MemoryPostAuthDestinationStore implements PostAuthDestinationStore {
  _MemoryPostAuthDestinationStore(this.destination);

  String? destination;

  @override
  Future<void> clear() async => destination = null;

  @override
  Future<void> save(String? destination) async =>
      this.destination = destination;

  @override
  Future<String?> take() async {
    final value = destination;
    destination = null;
    return value;
  }
}

void main() {
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  late MockTwoFactorService mockTwoFactor;
  late MockEdgeFunctionClient mockEdgeFunctionClient;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async => null);
    mockTwoFactor = MockTwoFactorService();
    mockEdgeFunctionClient = MockEdgeFunctionClient();
    when(
      () => mockTwoFactor.challengeAndVerify(
        factorId: any(named: 'factorId'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => false);
    when(() => mockEdgeFunctionClient.checkMfaLockout()).thenAnswer(
      (_) async => const EdgeFunctionResult(
        success: true,
        data: {'locked': false, 'remaining_seconds': 0},
      ),
    );
    when(() => mockEdgeFunctionClient.resetMfaLockout()).thenAnswer(
      (_) async => const EdgeFunctionResult(success: true, data: {}),
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  Widget createSubject({
    String factorId = 'test-factor-id',
    String? returnTo,
    String? storedDestination,
  }) {
    final router = GoRouter(
      initialLocation: '/2fa-verify',
      routes: [
        GoRoute(
          path: '/2fa-verify',
          builder: (_, __) =>
              TwoFactorVerifyScreen(factorId: factorId, returnTo: returnTo),
        ),
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(body: Text('Settings')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        twoFactorServiceProvider.overrideWithValue(mockTwoFactor),
        edgeFunctionClientProvider.overrideWithValue(mockEdgeFunctionClient),
        postAuthDestinationStoreProvider.overrideWithValue(
          _MemoryPostAuthDestinationStore(storedDestination),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('TwoFactorVerifyScreen', () {
    testWidgets('renders TwoFactorVerifyScreen without crashing', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(TwoFactorVerifyScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with 2fa_verify title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text(l10n('auth.2fa_verify')), findsOneWidget);
    });

    testWidgets('shows 2fa_verify_title heading', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text(l10n('auth.2fa_verify_title')), findsOneWidget);
    });

    testWidgets('shows 2fa_verify_desc text', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text(l10n('auth.2fa_verify_desc')), findsOneWidget);
    });

    testWidgets('shows 2fa_verify_hint text', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text(l10n('auth.2fa_verify_hint')), findsOneWidget);
    });

    testWidgets('shows two_factor icon', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // AppIcon widget renders the SVG icon
      expect(
        find.byType(Icon).evaluate().isNotEmpty ||
            find
                .byWidgetPredicate(
                  (w) => w.runtimeType.toString().contains('AppIcon'),
                )
                .evaluate()
                .isNotEmpty,
        isTrue,
      );
    });

    testWidgets('does not show loading or error initially', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // No loading indicator at start (before any OTP entered)
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('fails closed when server lockout check returns failure', (
      tester,
    ) async {
      when(() => mockEdgeFunctionClient.checkMfaLockout()).thenAnswer(
        (_) async => EdgeFunctionResult.failure('no authenticated session'),
      );

      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text(l10n('auth.2fa_server_unavailable')), findsOneWidget);
    });

    testWidgets('restores persisted returnTo after successful verification', (
      tester,
    ) async {
      when(
        () => mockTwoFactor.challengeAndVerify(
          factorId: any(named: 'factorId'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(createSubject(storedDestination: '/settings'));
      await tester.pumpAndSettle();

      for (final field in find.byType(TextFormField).evaluate()) {
        await tester.enterText(find.byWidget(field.widget), '1');
        await tester.pump();
      }
      verify(
        () => mockTwoFactor.challengeAndVerify(
          factorId: 'test-factor-id',
          code: '111111',
        ),
      ).called(1);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      for (var i = 0; i < 20 && find.text('Settings').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
