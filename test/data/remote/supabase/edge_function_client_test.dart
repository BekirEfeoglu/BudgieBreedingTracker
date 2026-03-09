import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

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
    when(() => mockAuth.currentSession).thenReturn(null);
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
      expect(result.error, contains('Status 500'));
    });
  });

  group('EdgeFunctionClient', () {
    test('invoke forwards body+headers and returns parsed result', () async {
      final body = <String, dynamic>{'x': 1};
      final headers = <String, String>{'x-trace': 'abc'};
      when(
        () =>
            mockFunctions.invoke('test-function', body: body, headers: headers),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200, data: {'ok': true}),
      );

      final result = await client.invoke(
        'test-function',
        body: body,
        headers: headers,
      );

      expect(result.success, isTrue);
      expect(result.data, {'ok': true});
      verify(
        () =>
            mockFunctions.invoke('test-function', body: body, headers: headers),
      ).called(1);
    });

    test(
      'invoke returns failure when function responds with error status',
      () async {
        when(
          () =>
              mockFunctions.invoke('test-function', body: null, headers: null),
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
        () => mockFunctions.invoke('explode', body: null, headers: null),
      ).thenThrow(Exception('network down'));

      final result = await client.invoke('explode');

      expect(result.success, isFalse);
      expect(result.error, contains('network down'));
    });

    test('calculateGenetics sends expected payload', () async {
      Map<String, dynamic>? capturedBody;
      when(
        () => mockFunctions.invoke(
          'calculate-genetics',
          body: any(named: 'body'),
          headers: null,
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
            headers: null,
          ),
        ).thenAnswer((invocation) async {
          capturedBody = Map<String, dynamic>.from(
            invocation.namedArguments[#body] as Map,
          );
          return FunctionResponse(status: 200, data: {'report_id': 'r1'});
        });

        final result = await client.generateReport(
          userId: 'u1',
          reportType: 'summary',
          options: {'range': 'month'},
        );

        expect(result.success, isTrue);
        expect(capturedBody, {
          'user_id': 'u1',
          'report_type': 'summary',
          'options': {'range': 'month'},
        });
      },
    );

    test('checkSystemHealth invokes the system-health function', () async {
      when(
        () => mockFunctions.invoke('system-health', body: null, headers: null),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200, data: {'healthy': true}),
      );

      final result = await client.checkSystemHealth();

      expect(result.success, isTrue);
      expect(result.data?['healthy'], isTrue);
      verify(
        () => mockFunctions.invoke('system-health', body: null, headers: null),
      ).called(1);
    });
  });
}
