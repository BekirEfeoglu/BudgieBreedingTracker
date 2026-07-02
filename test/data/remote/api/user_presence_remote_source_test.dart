import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/api/user_presence_remote_source.dart';

class _FakeUser extends Fake implements User {
  _FakeUser(this.idValue);

  final String idValue;

  @override
  String get id => idValue;
}

class _FakeGoTrueClient extends Fake implements GoTrueClient {
  _FakeGoTrueClient(this._currentUser);

  final User? _currentUser;

  @override
  User? get currentUser => _currentUser;
}

class _FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  final eqCalls = <MapEntry<String, Object>>[];

  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) {
    eqCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(dynamic value) onValue, {
    Function? onError,
  }) {
    return Future<dynamic>.value(<dynamic>[]).then(onValue, onError: onError);
  }
}

// ignore: must_be_immutable
class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final upsertBuilder = _FakeFilterBuilder();
  final updateBuilder = _FakeFilterBuilder();
  Object? upsertPayload;
  Object? updatePayload;

  @override
  PostgrestFilterBuilder<dynamic> upsert(
    Object values, {
    String? onConflict,
    bool defaultToNull = true,
    bool ignoreDuplicates = false,
  }) {
    upsertPayload = values;
    return upsertBuilder;
  }

  @override
  PostgrestFilterBuilder<dynamic> update(
    Object values, {
    bool defaultToNull = true,
  }) {
    updatePayload = values;
    return updateBuilder;
  }
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient({this.currentUserId});

  final String? currentUserId;
  final queryBuilder = _FakeQueryBuilder();
  String? requestedTable;

  @override
  GoTrueClient get auth =>
      _FakeGoTrueClient(currentUserId == null ? null : _FakeUser(currentUserId!));

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTable = table;
    return queryBuilder;
  }
}

void main() {
  group('UserPresenceRemoteSource', () {
    test('currentAuthUserId reflects the Supabase auth session', () {
      final client = _FakeSupabaseClient(currentUserId: 'user-1');
      final source = UserPresenceRemoteSource(client);

      expect(source.currentAuthUserId, 'user-1');
    });

    test('currentAuthUserId is null when signed out', () {
      final client = _FakeSupabaseClient();
      final source = UserPresenceRemoteSource(client);

      expect(source.currentAuthUserId, isNull);
    });

    test('upsertSession writes to the user_sessions table', () async {
      final client = _FakeSupabaseClient(currentUserId: 'user-1');
      final source = UserPresenceRemoteSource(client);

      await source.upsertSession({
        SupabaseConstants.colId: 'session-1',
        SupabaseConstants.colUserId: 'user-1',
      });

      expect(client.requestedTable, SupabaseConstants.userSessionsTable);
      final payload =
          client.queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload[SupabaseConstants.colId], 'session-1');
      expect(payload[SupabaseConstants.colUserId], 'user-1');
    });

    test('updateSession scopes the update to id and user_id', () async {
      final client = _FakeSupabaseClient(currentUserId: 'user-1');
      final source = UserPresenceRemoteSource(client);

      await source.updateSession(
        sessionId: 'session-1',
        userId: 'user-1',
        payload: {SupabaseConstants.colIsActive: false},
      );

      expect(client.requestedTable, SupabaseConstants.userSessionsTable);
      final payload =
          client.queryBuilder.updatePayload as Map<String, dynamic>;
      expect(payload[SupabaseConstants.colIsActive], false);
      expect(
        client.queryBuilder.updateBuilder.eqCalls.any(
          (call) =>
              call.key == SupabaseConstants.colId && call.value == 'session-1',
        ),
        isTrue,
      );
      expect(
        client.queryBuilder.updateBuilder.eqCalls.any(
          (call) =>
              call.key == SupabaseConstants.colUserId && call.value == 'user-1',
        ),
        isTrue,
      );
    });
  });
}
