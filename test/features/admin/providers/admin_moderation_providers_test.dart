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

class _RpcCall {
  _RpcCall(this.fn, this.params);

  final String fn;
  final Map<String, dynamic>? params;
}

class _FakeMaybeSingle extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  _FakeMaybeSingle(this.result);
  final PostgrestMap? result;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestMap? value) onValue, {
    Function? onError,
  }) => Future<PostgrestMap?>.value(result).then(onValue, onError: onError);
}

// ignore: must_be_immutable
class _FakeFilter extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
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
  }) => this;

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() =>
      _FakeMaybeSingle(result.isNotEmpty ? result.first : null);

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    return Future<PostgrestList>.value(result).then(onValue, onError: onError);
  }
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
    return _FakeFilter(
      const [],
      onEq: (c, v) => call.eqCalls.add(MapEntry(c, v)),
    );
  }
}

class _FakeRpc<T> extends Fake implements PostgrestFilterBuilder<T> {
  _FakeRpc({this.error, this.gate});

  final Object? error;
  final Future<void>? gate;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(T value) onValue, {
    Function? onError,
  }) {
    final source = gate == null
        ? Future<T>.value(null as T)
        : gate!.then((_) => null as T);
    if (error != null) {
      final failing = gate == null
          ? Future<T>.error(error!)
          : gate!.then<T>((_) => Future<T>.error(error!));
      return failing.then(onValue, onError: onError);
    }
    return source.then(onValue, onError: onError);
  }
}

class _Store {
  _Store({
    required this.adminRow,
    this.posts = const [],
    this.rpcGate,
    this.rpcError,
  });
  final PostgrestList adminRow;
  final PostgrestList posts;

  final Completer<void>? rpcGate;
  final Object? rpcError;
  final updates = <_UpdateCall>[];
  final rpcCalls = <_RpcCall>[];

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

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    get = false,
  }) {
    store.rpcCalls.add(_RpcCall(fn, params));
    return _FakeRpc<T>(error: store.rpcError, gate: store.rpcGate?.future);
  }
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
    test('approvePost sends approve decision to audited RPC', () async {
      final store = _Store(adminRow: _adminRow());
      final container = _container(store);

      await container
          .read(adminModerationProvider.notifier)
          .approvePost('post-1');

      expect(store.rpcCalls, hasLength(1));
      expect(store.rpcCalls.single.params, {
        'p_entity_type': 'post',
        'p_entity_id': 'post-1',
        'p_action': 'approve',
      });
      expect(store.updates, isEmpty);
    });

    test(
      'approvePost delegates moderation and audit to the server RPC',
      () async {
        final store = _Store(adminRow: _adminRow());
        final container = _container(store);

        await container
            .read(adminModerationProvider.notifier)
            .approvePost('post-1');

        expect(store.rpcCalls, hasLength(1));
        expect(store.rpcCalls.single.fn, 'admin_moderate_community_content');
        expect(store.rpcCalls.single.params, {
          'p_entity_type': 'post',
          'p_entity_id': 'post-1',
          'p_action': 'approve',
        });
        expect(store.updates, isEmpty);
      },
    );

    test('deletePost soft-deletes and clears review flag', () async {
      final store = _Store(adminRow: _adminRow());
      final container = _container(store);

      await container
          .read(adminModerationProvider.notifier)
          .deletePost('post-1');

      expect(store.rpcCalls.single.params, {
        'p_entity_type': 'post',
        'p_entity_id': 'post-1',
        'p_action': 'delete',
      });
      expect(store.updates, isEmpty);
    });

    test('deleteComment soft-deletes the comment', () async {
      final store = _Store(adminRow: _adminRow());
      final container = _container(store);

      await container
          .read(adminModerationProvider.notifier)
          .deleteComment('comment-1');

      expect(store.rpcCalls.single.params, {
        'p_entity_type': 'comment',
        'p_entity_id': 'comment-1',
        'p_action': 'delete',
      });
      expect(store.updates, isEmpty);
    });

    test('marks only the acting item as processing, then clears it', () async {
      final gate = Completer<void>();
      final store = _Store(adminRow: _adminRow(), rpcGate: gate);
      final container = _container(store);

      expect(container.read(adminModerationProvider).processingIds, isEmpty);

      // Don't await: the synchronous prefix of _run adds the id before the
      // first await, so the in-flight state is observable immediately.
      final future = container
          .read(adminModerationProvider.notifier)
          .approvePost('post-1');

      expect(
        container.read(adminModerationProvider).processingIds,
        contains('post-1'),
      );
      expect(
        container.read(adminModerationProvider).contains('post-2'),
        isFalse,
        reason: 'a different card must not be locked by post-1 processing',
      );

      gate.complete();
      await future;

      expect(container.read(adminModerationProvider).processingIds, isEmpty);
    });

    test('ignores a double-tap on an already-processing item', () async {
      final gate = Completer<void>();
      final store = _Store(adminRow: _adminRow(), rpcGate: gate);
      final container = _container(store);
      final notifier = container.read(adminModerationProvider.notifier);

      final first = notifier.deletePost('post-1');
      final second = notifier.deletePost('post-1'); // ignored while in flight

      gate.complete();
      await Future.wait([first, second]);

      // Only the first call issued a moderation RPC.
      expect(store.rpcCalls, hasLength(1));
      expect(container.read(adminModerationProvider).processingIds, isEmpty);
    });

    test('surfaces RPC errors and clears processing state', () async {
      final store = _Store(
        adminRow: _adminRow(),
        rpcError: Exception('network failed'),
      );
      final container = _container(store);

      await container
          .read(adminModerationProvider.notifier)
          .approvePost('post-1');

      final state = container.read(adminModerationProvider);
      expect(state.processingIds, isEmpty);
      expect(state.error, contains('admin.action_error'));
    });
  });
}
