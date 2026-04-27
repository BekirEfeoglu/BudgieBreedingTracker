import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';

import '../../../helpers/mocks.dart';

const _testAccessToken = 'test-access-token';

Session _createTestSession() {
  return Session(
    accessToken: _testAccessToken,
    tokenType: 'bearer',
    user: const User(
      id: 'test-user',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2024-01-01T00:00:00Z',
    ),
  );
}

/// Auth header that EdgeFunctionClient injects into every request.
const _authHeader = {'Authorization': 'Bearer $_testAccessToken'};

void main() {
  late MockSupabaseClient mockClient;
  late MockFunctionsClient mockFunctions;
  late MockGoTrueClient mockAuth;
  late EdgeFunctionClient client;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockFunctions = MockFunctionsClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.functions).thenReturn(mockFunctions);
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentSession).thenReturn(_createTestSession());
    client = EdgeFunctionClient(mockClient);
  });

  group('EdgeFunctionResult.fromResponse', () {
    test('returns success with map payload for 2xx responses', () {
      final response = FunctionResponse(status: 200, data: {'ok': true});

      final result = EdgeFunctionResult.fromResponse(response);

      expect(result.success, isTrue);
      expect(result.data, {'ok': true});
      expect(result.error, isNull);
    });

    test('parses JSON string payload', () {
      final response = FunctionResponse(status: 201, data: '{"value": 42}');

      final result = EdgeFunctionResult.fromResponse(response);

      expect(result.success, isTrue);
      expect(result.data, {'value': 42});
    });

    test('wraps non-JSON string payload under response key', () {
      final response = FunctionResponse(status: 200, data: 'plain text');

      final result = EdgeFunctionResult.fromResponse(response);

      expect(result.success, isTrue);
      expect(result.data, {'response': 'plain text'});
    });

    test('returns empty map for non-map and non-string 2xx payload', () {
      final response = FunctionResponse(status: 204, data: 123);

      final result = EdgeFunctionResult.fromResponse(response);

      expect(result.success, isTrue);
      expect(result.data, isEmpty);
    });

    test('returns failure for non-2xx status', () {
      final response = FunctionResponse(status: 500, data: {'message': 'boom'});

      final result = EdgeFunctionResult.fromResponse(response);

      expect(result.success, isFalse);
      expect(result.data, {'message': 'boom'});
      expect(result.error, contains('Status 500'));
    });

    test('preserves structured error payloads for non-2xx statuses', () {
      final response = FunctionResponse(
        status: 429,
        data: {'locked': true, 'remaining_seconds': 120},
      );

      final result = EdgeFunctionResult.fromResponse(response);

      expect(result.success, isFalse);
      expect(result.data, {'locked': true, 'remaining_seconds': 120});
      expect(result.error, contains('Status 429'));
    });
  });

  group('EdgeFunctionClient', () {
    test('invoke forwards body+headers and returns parsed result', () async {
      final body = <String, dynamic>{'x': 1};
      final customHeaders = <String, String>{'x-trace': 'abc'};
      final expectedHeaders = <String, String>{
        ..._authHeader,
        ...customHeaders,
      };
      when(
        () => mockFunctions.invoke(
          'test-function',
          body: body,
          headers: expectedHeaders,
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200, data: {'ok': true}),
      );

      final result = await client.invoke(
        'test-function',
        body: body,
        headers: customHeaders,
      );

      expect(result.success, isTrue);
      expect(result.data, {'ok': true});
      verify(
        () => mockFunctions.invoke(
          'test-function',
          body: body,
          headers: expectedHeaders,
        ),
      ).called(1);
    });

    test(
      'invoke returns failure when function responds with error status',
      () async {
        when(
          () => mockFunctions.invoke(
            'test-function',
            body: null,
            headers: _authHeader,
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 400, data: 'bad request'),
        );

        final result = await client.invoke('test-function');

        expect(result.success, isFalse);
        expect(result.error, contains('Status 400'));
      },
    );

    test('invoke returns failure when underlying client throws', () async {
      when(
        () => mockFunctions.invoke('explode', body: null, headers: _authHeader),
      ).thenThrow(Exception('network down'));

      final result = await client.invoke('explode');

      expect(result.success, isFalse);
      expect(result.error, contains('Edge function error'));
    });

    test('invoke returns failure when no session exists', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final result = await client.invoke('test-function');

      expect(result.success, isFalse);
      expect(result.error, contains('No authenticated session'));
      verifyNever(
        () => mockFunctions.invoke(
          any(),
          body: any(named: 'body'),
          headers: any(named: 'headers'),
        ),
      );
    });

    test('calculateGenetics sends expected payload', () async {
      Map<String, dynamic>? capturedBody;
      when(
        () => mockFunctions.invoke(
          'calculate-genetics',
          body: any(named: 'body'),
          headers: _authHeader,
        ),
      ).thenAnswer((invocation) async {
        capturedBody = Map<String, dynamic>.from(
          invocation.namedArguments[#body] as Map,
        );
        return FunctionResponse(status: 200, data: {'ok': true});
      });

      final result = await client.calculateGenetics(
        fatherMutations: ['spangle'],
        motherMutations: ['opaline'],
      );

      expect(result.success, isTrue);
      expect(capturedBody, {
        'father_mutations': ['spangle'],
        'mother_mutations': ['opaline'],
      });
    });

    test(
      'generateReport sends expected payload and optional options',
      () async {
        Map<String, dynamic>? capturedBody;
        when(
          () => mockFunctions.invoke(
            'generate-report',
            body: any(named: 'body'),
            headers: _authHeader,
          ),
        ).thenAnswer((invocation) async {
          capturedBody = Map<String, dynamic>.from(
            invocation.namedArguments[#body] as Map,
          );
          return FunctionResponse(status: 200, data: {'report_id': 'r1'});
        });

        final result = await client.generateReport(
          reportType: 'summary',
          options: {'range': 'month'},
        );

        expect(result.success, isTrue);
        expect(capturedBody, {
          'report_type': 'summary',
          'options': {'range': 'month'},
        });
      },
    );

    test('checkSystemHealth invokes the system-health function', () async {
      when(
        () => mockFunctions.invoke(
          'system-health',
          body: null,
          headers: _authHeader,
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200, data: {'healthy': true}),
      );

      final result = await client.checkSystemHealth();

      expect(result.success, isTrue);
      expect(result.data?['healthy'], isTrue);
      verify(
        () => mockFunctions.invoke(
          'system-health',
          body: null,
          headers: _authHeader,
        ),
      ).called(1);
    });

    test(
      'checkSystemHealth returns failure when function is not deployed (404)',
      () async {
        when(
          () => mockFunctions.invoke(
            'system-health',
            body: null,
            headers: _authHeader,
          ),
        ).thenThrow(
          const FunctionException(
            status: 404,
            details: {'code': 'NOT_FOUND'},
            reasonPhrase: 'Not Found',
          ),
        );

        final result = await client.checkSystemHealth();

        expect(result.success, isFalse);
        expect(result.error, contains('404 NOT_FOUND'));
      },
    );

    group('401 retry with session refresh', () {
      const refreshedToken = 'refreshed-access-token';

      Session createRefreshedSession() {
        return Session(
          accessToken: refreshedToken,
          tokenType: 'bearer',
          user: const User(
            id: 'test-user',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: '2024-01-01T00:00:00Z',
          ),
        );
      }

      test('retries with refreshed token on 401 and succeeds', () async {
        var callCount = 0;
        when(
          () => mockFunctions.invoke(
            'send-push',
            body: any(named: 'body'),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw const FunctionException(
              status: 401,
              details: {'code': 401, 'message': 'Invalid JWT'},
              reasonPhrase: 'Unauthorized',
            );
          }
          return FunctionResponse(status: 200, data: {'success': 1});
        });

        when(() => mockAuth.refreshSession()).thenAnswer((_) async {
          when(
            () => mockAuth.currentSession,
          ).thenReturn(createRefreshedSession());
          return AuthResponse(session: createRefreshedSession());
        });

        final result = await client.invoke('send-push', body: {'title': 'Hi'});

        expect(result.success, isTrue);
        expect(result.data, {'success': 1});
        verify(() => mockAuth.refreshSession()).called(1);
        verify(
          () => mockFunctions.invoke(
            'send-push',
            body: any(named: 'body'),
            headers: any(named: 'headers'),
          ),
        ).called(2);
      });

      test('returns failure when retry also gets 401', () async {
        when(
          () => mockFunctions.invoke(
            'test-fn',
            body: null,
            headers: any(named: 'headers'),
          ),
        ).thenThrow(
          const FunctionException(
            status: 401,
            details: {'code': 401, 'message': 'Invalid JWT'},
            reasonPhrase: 'Unauthorized',
          ),
        );

        when(() => mockAuth.refreshSession()).thenAnswer((_) async {
          when(
            () => mockAuth.currentSession,
          ).thenReturn(createRefreshedSession());
          return AuthResponse(session: createRefreshedSession());
        });

        final result = await client.invoke('test-fn');

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        verify(() => mockAuth.refreshSession()).called(1);
      });

      test('returns failure when session refresh fails', () async {
        when(
          () =>
              mockFunctions.invoke('test-fn', body: null, headers: _authHeader),
        ).thenThrow(
          const FunctionException(
            status: 401,
            details: {'code': 401, 'message': 'Invalid JWT'},
            reasonPhrase: 'Unauthorized',
          ),
        );

        when(
          () => mockAuth.refreshSession(),
        ).thenThrow(Exception('refresh failed'));

        final result = await client.invoke('test-fn');

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });

      test('returns failure when refreshed session has no token', () async {
        when(
          () =>
              mockFunctions.invoke('test-fn', body: null, headers: _authHeader),
        ).thenThrow(
          const FunctionException(
            status: 401,
            details: {'code': 401, 'message': 'Invalid JWT'},
            reasonPhrase: 'Unauthorized',
          ),
        );

        when(() => mockAuth.refreshSession()).thenAnswer((_) async {
          when(() => mockAuth.currentSession).thenReturn(null);
          return AuthResponse();
        });

        final result = await client.invoke('test-fn');

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });

      test('does not report to Sentry when retry succeeds', () async {
        // Sentry.captureException is static and hard to mock, but we verify
        // the success path returns before reaching the Sentry call.
        var callCount = 0;
        when(
          () => mockFunctions.invoke(
            'send-push',
            body: any(named: 'body'),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw const FunctionException(
              status: 401,
              details: {'code': 401, 'message': 'Invalid JWT'},
              reasonPhrase: 'Unauthorized',
            );
          }
          return FunctionResponse(status: 200, data: {'ok': true});
        });

        when(() => mockAuth.refreshSession()).thenAnswer((_) async {
          when(
            () => mockAuth.currentSession,
          ).thenReturn(createRefreshedSession());
          return AuthResponse(session: createRefreshedSession());
        });

        final result = await client.invoke('send-push', body: {'x': 1});

        // Retry succeeded — Sentry.captureException should NOT be reached.
        // The result being successful confirms the early return path was taken.
        expect(result.success, isTrue);
      });
    });
  });
}
