import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_moderation_providers.dart';
import 'package:budgie_breeding_tracker/shared/providers/auth.dart';

// ── Minimal Supabase fakes ──────────────────────────────────

/// Records an update payload + the filters it was scoped by.
class _UpdateCall {
  _UpdateCall(this.table, this.values);
  final String table;
  final Map<String, dynamic> values;
  final eqCalls = <MapEntry<String, Object>>[];
}

class _FakeMaybeSingle extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  _FakeMaybeSingle(this.result);
  final PostgrestMap? result;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestMap? value) onValue, {
    Function? onError,
  }) =>
      Future<PostgrestMap?>.value(result).then(onValue, onError: onError);
}

// ignore: must_be_immutable
class _FakeFilter extends Fake implements PostgrestFilterBuilder<PostgrestList> {
  _FakeFilter(this.result, {this.onEq});
  PostgrestList result;
  final void Function(String column, Object value)? onEq;

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    onEq?.call(column, value);
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestList> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) =>
      this;

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() =>
      _FakeMaybeSingle(result.isNotEmpty ? result.first : null);

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) =>
      Future<PostgrestList>.value(result).then(onValue, onError: onError);
}

class _FakeQuery extends Fake implements SupabaseQueryBuilder {
  _FakeQuery(this.table, this.store);
  final String table;
  final _Store store;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    if (table == SupabaseConstants.profilesTable) {
      return _FakeFilter(store.adminRow);
    }
    return _FakeFilter(store.rowsFor(table));
  }

  @override
  PostgrestFilterBuilder<PostgrestList> update(Map values) {
    final call = _UpdateCall(table, Map<String, dynamic>.from(values));
    store.updates.add(call);
    return _FakeFilter(const [], onEq: (c, v) => call.eqCalls.add(MapEntry(c, v)));
  }
}

class _Store {
  _Store({required this.adminRow, this.posts = const []});
  final PostgrestList adminRow;
  final PostgrestList posts;
  final updates = <_UpdateCall>[];

  PostgrestList rowsFor(String table) {
    if (table == SupabaseConstants.communityPostsTable) return posts;
    return const [];
  }
}

class _FakeClient extends Fake implements SupabaseClient {
  _FakeClient(this.store);
  final _Store store;

  @override
  SupabaseQueryBuilder from(String table) => _FakeQuery(table, store);
}

// ── Helpers ─────────────────────────────────────────────────

PostgrestList _adminRow({String role = 'admin', bool isActive = true}) => [
      {'role': role, 'is_active': isActive},
    ];

Map<String, dynamic> _postRow({String id = 'post-1'}) => {
      'id': id,
      'user_id': 'author-1',
      'content': 'hello',
      'needs_review': true,
    };

ProviderContainer _container(_Store store) {
  final container = ProviderContainer(
    overrides: [
      supabaseClientProvider.overrideWithValue(_FakeClient(store)),
      currentUserIdProvider.overrideWithValue('admin-1'),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('adminPendingPostsProvider', () {
    test('returns posts needing review for an admin', () async {
      final store = _Store(adminRow: _adminRow(), posts: [_postRow()]);
      final container = _container(store);

      final posts = await container.read(adminPendingPostsProvider.future);

      expect(posts, hasLength(1));
      expect(posts.first.id, 'post-1');
    });

    // requireAdmin rejection (non-admin / inactive / anonymous) is covered
    // exhaustively in admin_auth_utils_test.dart; not re-asserted per provider.
  });

  group('AdminModerationNotifier', () {
    test('approvePost clears needs_review without deleting', () async {
      final store = _Store(adminRow: _adminRow());
      final container = _container(store);

      await container.read(adminModerationProvider.notifier).approvePost('post-1');

      expect(store.updates, hasLength(1));
      final call = store.updates.single;
      expect(call.table, SupabaseConstants.communityPostsTable);
      expect(call.values[SupabaseConstants.colNeedsReview], false);
      expect(call.values.containsKey(SupabaseConstants.colIsDeleted), isFalse);
      expect(call.eqCalls.single.key, SupabaseConstants.colId);
      expect(call.eqCalls.single.value, 'post-1');
    });

    test('deletePost soft-deletes and clears review flag', () async {
      final store = _Store(adminRow: _adminRow());
      final container = _container(store);

      await container.read(adminModerationProvider.notifier).deletePost('post-1');

      final call = store.updates.single;
      expect(call.values[SupabaseConstants.colIsDeleted], true);
      expect(call.values[SupabaseConstants.colNeedsReview], false);
    });

    test('deleteComment soft-deletes the comment', () async {
      final store = _Store(adminRow: _adminRow());
      final container = _container(store);

      await container
          .read(adminModerationProvider.notifier)
          .deleteComment('comment-1');

      final call = store.updates.single;
      expect(call.table, SupabaseConstants.communityCommentsTable);
      expect(call.values[SupabaseConstants.colIsDeleted], true);
      expect(call.eqCalls.single.key, SupabaseConstants.colId);
      expect(call.eqCalls.single.value, 'comment-1');
    });
  });
}
