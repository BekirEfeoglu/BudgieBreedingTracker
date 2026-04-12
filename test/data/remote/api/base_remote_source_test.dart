import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

/// Concrete subclass for testing [BaseRemoteSource] behaviour.
class _TestRemoteSource extends BaseRemoteSource<Map<String, dynamic>> {
  _TestRemoteSource(super.client);

  @override
  String get tableName => 'test_table';

  @override
  Map<String, dynamic> fromJson(Map<String, dynamic> json) => json;

  @override
  Map<String, dynamic> toSupabaseJson(Map<String, dynamic> model) => model;
}

/// Concrete subclass for testing [BaseRemoteSourceNoSoftDelete].
class _TestNoSoftDeleteSource
    extends BaseRemoteSourceNoSoftDelete<Map<String, dynamic>> {
  _TestNoSoftDeleteSource(super.client);

  @override
  String get tableName => 'test_no_sd';

  @override
  Map<String, dynamic> fromJson(Map<String, dynamic> json) => json;

  @override
  Map<String, dynamic> toSupabaseJson(Map<String, dynamic> model) => model;
}

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeFilterBuilder<dynamic> upsertBuilder;
  late FakeFilterBuilder<dynamic> deleteBuilder;
  late FakeSupabaseClient client;
  late _TestRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    upsertBuilder = stack.upsertBuilder;
    deleteBuilder = stack.deleteBuilder;
    client = stack.client;
    source = _TestRemoteSource(client);
  });

  group('BaseRemoteSource', () {
    group('fetchAll', () {
      test('returns parsed results with timing wrapper', () async {
        selectBuilder.result = [
          {'id': '1', 'name': 'a'},
          {'id': '2', 'name': 'b'},
        ];

        final result = await source.fetchAll('user-1');

        expect(result, hasLength(2));
        expect(result.first['id'], '1');
        expect(
          selectBuilder.eqCalls.map((e) => '${e.key}:${e.value}'),
          containsAll(['user_id:user-1', 'is_deleted:false']),
        );
        expect(selectBuilder.orderCalls, contains('created_at'));
      });

      test('returns empty list when no records', () async {
        selectBuilder.result = const [];
        final result = await source.fetchAll('user-1');
        expect(result, isEmpty);
      });

      test('throws NetworkException on failure', () async {
        selectBuilder.error = Exception('network fail');
        expect(
          () => source.fetchAll('user-1'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('fetchById', () {
      test('returns model when found', () async {
        selectBuilder.singleResult = {'id': '1', 'name': 'test'};
        final result = await source.fetchById('1', userId: 'user-1');
        expect(result, isNotNull);
        expect(result!['id'], '1');
        final eqKeys = selectBuilder.eqCalls
            .map((e) => '${e.key}:${e.value}')
            .toList();
        expect(eqKeys, containsAll(['id:1', 'user_id:user-1']));
      });

      test('returns null when not found', () async {
        selectBuilder.singleResult = null;
        final result = await source.fetchById('missing', userId: 'user-1');
        expect(result, isNull);
      });
    });

    group('fetchUpdatedSince', () {
      test('applies gte filter on updated_at without is_deleted filter', () async {
        selectBuilder.result = const [];
        final since = DateTime(2025, 6, 1);

        await source.fetchUpdatedSince('user-1', since);

        final gteKeys = selectBuilder.gteCalls
            .map((e) => '${e.key}:${e.value}')
            .toList();
        expect(gteKeys, contains('updated_at:${since.toIso8601String()}'));
        final eqKeys = selectBuilder.eqCalls
            .map((e) => '${e.key}:${e.value}')
            .toList();
        expect(eqKeys, contains('user_id:user-1'));
        expect(eqKeys, isNot(contains('is_deleted:false')));
      });
    });

    group('upsert', () {
      test('sends serialized payload', () async {
        final model = {'id': '1', 'name': 'test'};
        await source.upsert(model);
        expect(client.requestedTable, 'test_table');
      });

      test('throws NetworkException on failure', () async {
        upsertBuilder.error = Exception('upsert fail');
        expect(
          () => source.upsert({'id': '1'}),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('upsertAll', () {
      test('skips empty list without querying', () async {
        await source.upsertAll([]);
        expect(client.requestedTable, isNull);
      });

      test('sends batch payload', () async {
        await source.upsertAll([
          {'id': '1'},
          {'id': '2'},
        ]);
        expect(client.requestedTable, 'test_table');
      });
    });

    group('deleteById', () {
      test('applies eq filter on id and user_id', () async {
        await source.deleteById('item-1', userId: 'user-1');

        expect(client.requestedTable, 'test_table');
        final eqKeys = deleteBuilder.eqCalls
            .map((e) => '${e.key}:${e.value}')
            .toList();
        expect(eqKeys, containsAll(['id:item-1', 'user_id:user-1']));
      });
    });

    group('handleError', () {
      test('wraps generic error as NetworkException', () {
        final result = source.handleError(
          Exception('generic'),
          StackTrace.current,
        );
        expect(result, isA<NetworkException>());
      });

      test('passes through AppException', () {
        const original = DatabaseException('db fail');
        final result = source.handleError(original, StackTrace.current);
        expect(result, same(original));
      });

      test('sanitizes PostgrestException with SQL syntax error', () {
        final result = source.handleError(
          const PostgrestException(
            message: 'syntax error at or near "DROP TABLE"',
            code: '42601',
          ),
          StackTrace.current,
        );
        expect(result, isA<NetworkException>());
        expect(result.message, 'Database operation failed');
      });

      test('sanitizes PostgrestException with RLS policy violation', () {
        final result = source.handleError(
          const PostgrestException(
            message: 'new row violates row-level security policy for table "birds"',
            code: '42501',
          ),
          StackTrace.current,
        );
        expect(result, isA<NetworkException>());
        expect(result.message, 'Database operation failed');
      });

      test('sanitizes PostgrestException with constraint error', () {
        final result = source.handleError(
          const PostgrestException(
            message: 'violates foreign key constraint "fk_birds_user_id"',
            code: '23503',
          ),
          StackTrace.current,
        );
        expect(result, isA<NetworkException>());
        expect(result.message, 'Database operation failed');
      });

      test('sanitizes PostgrestException with permission denied', () {
        final result = source.handleError(
          const PostgrestException(
            message: 'permission denied for table birds',
            code: '42501',
          ),
          StackTrace.current,
        );
        expect(result, isA<NetworkException>());
        expect(result.message, 'Database operation failed');
      });

      test('preserves non-sensitive PostgrestException message', () {
        final result = source.handleError(
          const PostgrestException(
            message: 'Request timeout',
            code: '57014',
          ),
          StackTrace.current,
        );
        expect(result, isA<NetworkException>());
        expect(result.message, 'Request timeout');
      });

      test('sanitizes generic error with sensitive content', () {
        final result = source.handleError(
          Exception('relation "secret_table" does not exist'),
          StackTrace.current,
        );
        expect(result, isA<NetworkException>());
        expect(result.message, 'Database operation failed');
      });

      test('preserves non-sensitive message containing generic words', () {
        // "column" and "policy" alone should NOT trigger sanitization
        final result = source.handleError(
          const PostgrestException(
            message: 'Missing column value in request body',
            code: '400',
          ),
          StackTrace.current,
        );
        expect(result, isA<NetworkException>());
        expect(result.message, 'Missing column value in request body');
      });
    });
  });

  group('BaseRemoteSourceNoSoftDelete', () {
    test('fetchAll omits is_deleted filter', () async {
      final stack = createFakeSupabaseStack();
      stack.selectBuilder.result = [
        {'id': '1'},
      ];
      final noSdSource = _TestNoSoftDeleteSource(stack.client);

      final result = await noSdSource.fetchAll('user-1');

      expect(result, hasLength(1));
      final eqKeys = stack.selectBuilder.eqCalls.map((e) => e.key).toList();
      expect(eqKeys, contains('user_id'));
      expect(eqKeys, isNot(contains('is_deleted')));
    });

    test('fetchUpdatedSince omits is_deleted filter', () async {
      final stack = createFakeSupabaseStack();
      stack.selectBuilder.result = const [];
      final noSdSource = _TestNoSoftDeleteSource(stack.client);

      await noSdSource.fetchUpdatedSince('user-1', DateTime(2025, 6, 1));

      final eqKeys = stack.selectBuilder.eqCalls.map((e) => e.key).toList();
      expect(eqKeys, contains('user_id'));
      expect(eqKeys, isNot(contains('is_deleted')));
    });
  });
}
