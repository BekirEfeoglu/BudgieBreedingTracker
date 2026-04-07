import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_health_providers.dart';

class MockEdgeFunctionClient extends Mock implements EdgeFunctionClient {}

void main() {
  late MockEdgeFunctionClient mockEdgeClient;

  setUp(() {
    mockEdgeClient = MockEdgeFunctionClient();
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        edgeFunctionClientProvider.overrideWithValue(mockEdgeClient),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('systemHealthProvider', () {
    test('returns health data on success', () async {
      when(() => mockEdgeClient.checkSystemHealth()).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: true,
          data: {'status': 'ok', 'checks': {}},
        ),
      );

      final container = buildContainer();
      final result = await container.read(systemHealthProvider.future);

      expect(result['status'], 'ok');
      verify(() => mockEdgeClient.checkSystemHealth()).called(1);
    });

    test('returns unavailable status on 404 error', () async {
      when(() => mockEdgeClient.checkSystemHealth()).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: false,
          error: '404 NOT_FOUND: system-health not deployed',
        ),
      );

      final container = buildContainer();
      final result = await container.read(systemHealthProvider.future);

      expect(result['status'], 'unavailable');
    });

    test('returns unavailable status on 401 auth error', () async {
      when(() => mockEdgeClient.checkSystemHealth()).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: false,
          error: '401 No authenticated session',
        ),
      );

      final container = buildContainer();
      final result = await container.read(systemHealthProvider.future);

      expect(result['status'], 'unavailable');
    });

    test('returns error status on other failures', () async {
      when(() => mockEdgeClient.checkSystemHealth()).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: false,
          error: 'Internal server error',
        ),
      );

      final container = buildContainer();
      final result = await container.read(systemHealthProvider.future);

      expect(result['status'], 'error');
      expect(result['message'], 'Internal server error');
    });

    test('returns empty map when success with no data', () async {
      when(() => mockEdgeClient.checkSystemHealth()).thenAnswer(
        (_) async => const EdgeFunctionResult(success: true, data: null),
      );

      final container = buildContainer();
      final result = await container.read(systemHealthProvider.future);

      expect(result, isEmpty);
    });
  });

  group('systemHealthAlertProvider', () {
    test('does not crash when health is unavailable', () async {
      when(() => mockEdgeClient.checkSystemHealth()).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: false,
          error: '404 NOT_FOUND',
        ),
      );

      final container = buildContainer();

      // Ensure systemHealthProvider resolves before watching alert provider
      await container.read(systemHealthProvider.future);

      // Reading systemHealthAlertProvider should not throw
      expect(() => container.read(systemHealthAlertProvider), returnsNormally);
    });

    test('does not crash when health returns ok status', () async {
      when(() => mockEdgeClient.checkSystemHealth()).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: true,
          data: {'status': 'ok'},
        ),
      );

      final container = buildContainer();
      await container.read(systemHealthProvider.future);

      expect(() => container.read(systemHealthAlertProvider), returnsNormally);
    });

    test('does not crash when health returns degraded status', () async {
      when(() => mockEdgeClient.checkSystemHealth()).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: true,
          data: {
            'status': 'degraded',
            'checks': {'database': 'slow', 'auth': 'ok'},
          },
        ),
      );

      final container = buildContainer();
      await container.read(systemHealthProvider.future);

      // Alert provider listens to health — should not throw
      expect(() => container.read(systemHealthAlertProvider), returnsNormally);
    });
  });
}
