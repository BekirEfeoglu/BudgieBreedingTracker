
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('systemHealthProvider', () {
    test('returns health data on success', () async {
      final mockEdgeClient = MockEdgeFunctionClient();
      when(() => mockEdgeClient.checkSystemHealth()).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: true,
          data: {'status': 'ok', 'checks': {'database': 'ok', 'auth': 'ok'}},
        ),
      );

      final container = ProviderContainer(
        overrides: [
          edgeFunctionClientProvider.overrideWithValue(mockEdgeClient),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(systemHealthProvider.future);
      expect(result['status'], 'ok');
      expect(result['checks'], isA<Map<String, dynamic>>());
    });

    test('returns unavailable on 404 error', () async {
      final mockEdgeClient = MockEdgeFunctionClient();
      when(() => mockEdgeClient.checkSystemHealth()).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: false,
          error: '404 NOT_FOUND: system-health not deployed',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          edgeFunctionClientProvider.overrideWithValue(mockEdgeClient),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(systemHealthProvider.future);
      expect(result['status'], 'unavailable');
    });

    test('returns unavailable on 401 auth error', () async {
      final mockEdgeClient = MockEdgeFunctionClient();
      when(() => mockEdgeClient.checkSystemHealth()).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: false,
          error: '401 No authenticated session',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          edgeFunctionClientProvider.overrideWithValue(mockEdgeClient),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(systemHealthProvider.future);
      expect(result['status'], 'unavailable');
    });

    test('returns error status with message on other failures', () async {
      final mockEdgeClient = MockEdgeFunctionClient();
      when(() => mockEdgeClient.checkSystemHealth()).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: false,
          error: 'Internal server error',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          edgeFunctionClientProvider.overrideWithValue(mockEdgeClient),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(systemHealthProvider.future);
      expect(result['status'], 'error');
      expect(result['message'], 'Internal server error');
    });

    test('returns empty map when data is null in success result', () async {
      final mockEdgeClient = MockEdgeFunctionClient();
      when(() => mockEdgeClient.checkSystemHealth()).thenAnswer(
        (_) async => const EdgeFunctionResult(success: true, data: null),
      );

      final container = ProviderContainer(
        overrides: [
          edgeFunctionClientProvider.overrideWithValue(mockEdgeClient),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(systemHealthProvider.future);
      expect(result, isEmpty);
    });

    test('returns success data map with all checks', () async {
      final mockEdgeClient = MockEdgeFunctionClient();
      when(() => mockEdgeClient.checkSystemHealth()).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: true,
          data: {
            'status': 'degraded',
            'checks': {
              'database': 'ok',
              'auth': 'ok',
              'storage': 'degraded',
              'edge_functions': 'ok',
            },
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          edgeFunctionClientProvider.overrideWithValue(mockEdgeClient),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(systemHealthProvider.future);
      expect(result['status'], 'degraded');
      final checks = result['checks'] as Map<String, dynamic>;
      expect(checks['storage'], 'degraded');
      expect(checks['database'], 'ok');
    });
  });

  group('systemHealthAlertProvider', () {
    late MockEdgeFunctionClient mockEdgeClient;
    late MockSupabaseClient mockSupabaseClient;

    setUp(() {
      mockEdgeClient = MockEdgeFunctionClient();
      mockSupabaseClient = MockSupabaseClient();
    });

    ProviderContainer createContainer({
      required AsyncValue<Map<String, dynamic>> healthValue,
    }) {
      return ProviderContainer(
        overrides: [
          systemHealthProvider.overrideWithValue(healthValue),
          edgeFunctionClientProvider.overrideWithValue(mockEdgeClient),
          supabaseClientProvider.overrideWithValue(mockSupabaseClient),
        ],
      );
    }

    test('does not send alert when status is ok', () {
      final container = createContainer(
        healthValue: const AsyncData({'status': 'ok'}),
      );
      addTearDown(container.dispose);

      container.read(systemHealthAlertProvider);

      verifyNever(
        () => mockEdgeClient.sendPush(
          userIds: any(named: 'userIds'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
        ),
      );
    });

    test('does not send alert when status is unavailable', () {
      final container = createContainer(
        healthValue: const AsyncData({'status': 'unavailable'}),
      );
      addTearDown(container.dispose);

      container.read(systemHealthAlertProvider);

      verifyNever(
        () => mockEdgeClient.sendPush(
          userIds: any(named: 'userIds'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
        ),
      );
    });

    test('does not send alert during loading', () {
      final container = createContainer(
        healthValue: const AsyncLoading(),
      );
      addTearDown(container.dispose);

      container.read(systemHealthAlertProvider);

      verifyNever(
        () => mockEdgeClient.sendPush(
          userIds: any(named: 'userIds'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
        ),
      );
    });

    test('does not send alert during error state', () {
      final container = createContainer(
        healthValue: AsyncError(Exception('error'), StackTrace.empty),
      );
      addTearDown(container.dispose);

      container.read(systemHealthAlertProvider);

      verifyNever(
        () => mockEdgeClient.sendPush(
          userIds: any(named: 'userIds'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
        ),
      );
    });

    test('triggers alert logic when status is degraded', () async {
      when(() => mockSupabaseClient.from(any())).thenThrow(
        Exception('expected: verifying alert triggers supabase query'),
      );

      final container = createContainer(
        healthValue: const AsyncData({
          'status': 'degraded',
          'checks': {'database': 'degraded', 'auth': 'ok'},
        }),
      );
      addTearDown(container.dispose);

      container.read(systemHealthAlertProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockSupabaseClient.from(any())).called(1);
    });

    test('triggers alert logic when status is error', () async {
      when(() => mockSupabaseClient.from(any())).thenThrow(
        Exception('expected: verifying error status triggers alert'),
      );

      final container = createContainer(
        healthValue: const AsyncData({
          'status': 'error',
          'message': 'System check failed',
        }),
      );
      addTearDown(container.dispose);

      container.read(systemHealthAlertProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockSupabaseClient.from(any())).called(1);
    });

    test('does not trigger supabase query when status is ok', () async {
      final container = createContainer(
        healthValue: const AsyncData({'status': 'ok'}),
      );
      addTearDown(container.dispose);

      container.read(systemHealthAlertProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(() => mockSupabaseClient.from(any()));
    });

    test('handles null status gracefully', () async {
      final container = createContainer(
        healthValue: const AsyncData({'checks': {'database': 'ok'}}),
      );
      addTearDown(container.dispose);

      container.read(systemHealthAlertProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // null status → early return, no supabase query
      verifyNever(() => mockSupabaseClient.from(any()));
    });

    test('handles empty checks map in degraded status', () async {
      when(() => mockSupabaseClient.from(any())).thenThrow(
        Exception('expected'),
      );

      final container = createContainer(
        healthValue: const AsyncData({
          'status': 'degraded',
          'checks': <String, dynamic>{},
        }),
      );
      addTearDown(container.dispose);

      container.read(systemHealthAlertProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockSupabaseClient.from(any())).called(1);
    });

    test('handles missing checks key in degraded status', () async {
      when(() => mockSupabaseClient.from(any())).thenThrow(
        Exception('expected'),
      );

      final container = createContainer(
        healthValue: const AsyncData({'status': 'degraded'}),
      );
      addTearDown(container.dispose);

      container.read(systemHealthAlertProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockSupabaseClient.from(any())).called(1);
    });
  });

  group('EdgeFunctionResult', () {
    test('success factory creates success result', () {
      const result = EdgeFunctionResult(
        success: true,
        data: {'key': 'value'},
      );
      expect(result.success, isTrue);
      expect(result.data, {'key': 'value'});
      expect(result.error, isNull);
    });

    test('failure factory creates failure result', () {
      final result = EdgeFunctionResult.failure('something went wrong');
      expect(result.success, isFalse);
      expect(result.error, 'something went wrong');
      expect(result.data, isNull);
    });

    test('success with null data', () {
      const result = EdgeFunctionResult(success: true);
      expect(result.success, isTrue);
      expect(result.data, isNull);
    });
  });

  group('systemHealthProvider override integration', () {
    test('overriding with data works correctly', () async {
      final container = ProviderContainer(
        overrides: [
          systemHealthProvider.overrideWithValue(
            const AsyncData({'status': 'ok', 'uptime': '99.9%'}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(systemHealthProvider.future);
      expect(result['status'], 'ok');
      expect(result['uptime'], '99.9%');
    });

    test('overriding with error propagates', () async {
      final container = ProviderContainer(
        overrides: [
          systemHealthProvider.overrideWithValue(
            AsyncError(Exception('health check failed'), StackTrace.empty),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(systemHealthProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
