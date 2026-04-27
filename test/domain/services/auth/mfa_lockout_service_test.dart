import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/providers/edge_function_provider.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';
import 'package:budgie_breeding_tracker/domain/services/auth/mfa_lockout_service.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockEdgeFunctionClient mockEdgeClient;

  setUp(() {
    mockEdgeClient = MockEdgeFunctionClient();
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [edgeFunctionClientProvider.overrideWithValue(mockEdgeClient)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('MfaLockoutService', () {
    test('parses locked payload from non-2xx Edge Function result', () async {
      when(() => mockEdgeClient.checkMfaLockout()).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: false,
          data: {'locked': true, 'remaining_seconds': 120},
          error: 'Status 429',
        ),
      );

      final service = buildContainer().read(mfaLockoutServiceProvider);
      final result = await service.check();

      expect(result.success, isTrue);
      expect(result.locked, isTrue);
      expect(result.remainingSeconds, 120);
    });

    test('throws when check fails without a lockout payload', () async {
      when(() => mockEdgeClient.checkMfaLockout()).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: false,
          data: {'error': 'Internal server error'},
          error: 'Status 500',
        ),
      );

      final service = buildContainer().read(mfaLockoutServiceProvider);

      await expectLater(service.check(), throwsA(isA<StateError>()));
    });

    test(
      'parses server lockout during failed verification recording',
      () async {
        when(() => mockEdgeClient.recordMfaFailure()).thenAnswer(
          (_) async => const EdgeFunctionResult(
            success: false,
            data: {'locked': true, 'remaining_seconds': 300},
            error: 'Status 429',
          ),
        );

        final service = buildContainer().read(mfaLockoutServiceProvider);
        final result = await service.recordFailure();

        expect(result.success, isTrue);
        expect(result.locked, isTrue);
        expect(result.remainingSeconds, 300);
      },
    );
  });
}
