import 'dart:async';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/admin_enums.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAdminMaybeSingleBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  _FakeAdminMaybeSingleBuilder({this.result});

  final PostgrestMap? result;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestMap? value) onValue, {
    Function? onError,
  }) {
    return Future<S>.value(onValue(result));
  }
}

class _FakeAdminSelectBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeAdminSelectBuilder({
    required this.maybeSingleBuilder,
    this.listResult = const [],
  });

  final _FakeAdminMaybeSingleBuilder maybeSingleBuilder;
  final List<Map<String, dynamic>> listResult;
  final eqCalls = <MapEntry<String, Object>>[];
  final _orderCalls = <({String column, bool ascending})>[];
  final _limitCalls = <int>[];

  String? get orderColumn =>
      _orderCalls.isEmpty ? null : _orderCalls.last.column;
  bool? get orderAscending =>
      _orderCalls.isEmpty ? null : _orderCalls.last.ascending;
  int? get limitCount => _limitCalls.isEmpty ? null : _limitCalls.last;

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    eqCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestList> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    _orderCalls.add((column: column, ascending: ascending));
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestList> limit(
    int count, {
    String? referencedTable,
  }) {
    _limitCalls.add(count);
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    return maybeSingleBuilder;
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    return Future<S>.value(onValue(listResult));
  }
}

class _FakeAdminQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeAdminQueryBuilder(this.filterBuilder);

  final _FakeAdminSelectBuilder filterBuilder;
  final selectedColumns = <String>[];

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    selectedColumns.add(columns);
    return filterBuilder;
  }
}

class _FakeAdminSupabaseClient extends Fake implements SupabaseClient {
  _FakeAdminSupabaseClient(this.queryBuilder);

  final _FakeAdminQueryBuilder queryBuilder;
  final requestedTables = <String>[];

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    return queryBuilder;
  }
}

/// Test-only notifier that returns the default [FeedbackQuery] from [build()].
/// Used to override [feedbackQueryProvider] without accessing state in the
/// constructor (which is forbidden in Riverpod 3).
class _FeedbackQueryNotifier extends FeedbackQueryNotifier {
  @override
  FeedbackQuery build() => const FeedbackQuery(limit: 50);
}

void main() {
  group('adminFeedbackProvider', () {
    test('throws AsyncError when admin check fails for anonymous user',
        () async {
      final maybeSingleBuilder = _FakeAdminMaybeSingleBuilder();
      final filterBuilder = _FakeAdminSelectBuilder(
        maybeSingleBuilder: maybeSingleBuilder,
        listResult: [
          {'id': 'fb-1', 'message': 'First'},
          {'id': 'fb-2', 'message': 'Second'},
        ],
      );
      final queryBuilder = _FakeAdminQueryBuilder(filterBuilder);
      final client = _FakeAdminSupabaseClient(queryBuilder);
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('anonymous'),
          supabaseClientProvider.overrideWithValue(client),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);
      final sub = container.listen(adminFeedbackProvider, (_, __) {});
      addTearDown(() {
        sub.close();
      });

      expect(
        () => container.read(adminFeedbackProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'returns newest feedback list with expected query modifiers',
      () async {
        final maybeSingleBuilder = _FakeAdminMaybeSingleBuilder(
          result: {'role': 'admin'},
        );
        final filterBuilder = _FakeAdminSelectBuilder(
          maybeSingleBuilder: maybeSingleBuilder,
          listResult: [
            {'id': 'fb-2', 'message': 'Second'},
            {'id': 'fb-1', 'message': 'First'},
          ],
        );
        final queryBuilder = _FakeAdminQueryBuilder(filterBuilder);
        final client = _FakeAdminSupabaseClient(queryBuilder);
        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            supabaseClientProvider.overrideWithValue(client),
            feedbackQueryProvider.overrideWith(_FeedbackQueryNotifier.new),
          ],
          retry: (_, __) => null,
        );
        addTearDown(container.dispose);
        final sub = container.listen(adminFeedbackProvider, (_, __) {});
        addTearDown(() {
          sub.close();
        });

        final result = await container.read(adminFeedbackProvider.future);

        expect(result, hasLength(2));
        expect(result.first['id'], 'fb-2');
        expect(client.requestedTables, [
          SupabaseConstants.profilesTable,
          SupabaseConstants.feedbackTable,
        ]);
        expect(queryBuilder.selectedColumns, ['role', '*']);
        expect(filterBuilder.orderColumn, 'created_at');
        expect(filterBuilder.orderAscending, isFalse);
        expect(filterBuilder.limitCount, 50);
      },
    );
  });

  group('feedbackStatusFilterProvider', () {
    test('defaults to null and can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(feedbackStatusFilterProvider), isNull);
      container.read(feedbackStatusFilterProvider.notifier).state =
          FeedbackStatus.open;
      expect(container.read(feedbackStatusFilterProvider), FeedbackStatus.open);
    });
  });
}
