import 'dart:async';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/domain/services/presence/user_presence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final insertBuilder = _FakeFilterBuilder();
  final updateBuilder = _FakeFilterBuilder();
  Object? insertPayload;
  Object? updatePayload;

  @override
  PostgrestFilterBuilder<dynamic> insert(
    Object values, {
    bool defaultToNull = true,
  }) {
    insertPayload = values;
    return insertBuilder;
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
  _FakeSupabaseClient({required this.currentUserId});

  final String currentUserId;
  final queryBuilder = _FakeQueryBuilder();
  String? requestedTable;

  @override
  GoTrueClient get auth => _FakeGoTrueClient(_FakeUser(currentUserId));

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTable = table;
    return queryBuilder;
  }
}

void main() {
  group('UserPresenceService', () {
    test(
      'startSession inserts a client generated id without select roundtrip',
      () async {
        final client = _FakeSupabaseClient(currentUserId: 'user-1');
        final service = UserPresenceService(client);

        final sessionId = await service.startSession('user-1');

        expect(client.requestedTable, SupabaseConstants.userSessionsTable);
        expect(sessionId, isNotNull);
        final payload =
            client.queryBuilder.insertPayload as Map<String, dynamic>;
        expect(payload['id'], sessionId);
        expect(payload['user_id'], 'user-1');
        expect(payload['is_active'], true);
        expect(payload['last_active_at'], isA<String>());
        expect(payload['expires_at'], isA<String>());
      },
    );

    test('startSession skips writes when auth user does not match', () async {
      final client = _FakeSupabaseClient(currentUserId: 'user-1');
      final service = UserPresenceService(client);

      final sessionId = await service.startSession('user-2');

      expect(sessionId, isNull);
      expect(client.queryBuilder.insertPayload, isNull);
    });

    test('heartbeat updates only the owned session row', () async {
      final client = _FakeSupabaseClient(currentUserId: 'user-1');
      final service = UserPresenceService(client);

      await service.heartbeat(userId: 'user-1', sessionId: 'session-1');

      final payload = Map<String, dynamic>.from(
        client.queryBuilder.updatePayload! as Map,
      );
      expect(payload['is_active'], true);
      expect(payload['last_active_at'], isA<String>());
      expect(
        client.queryBuilder.updateBuilder.eqCalls.any(
          (call) => call.key == 'id' && call.value == 'session-1',
        ),
        isTrue,
      );
      expect(
        client.queryBuilder.updateBuilder.eqCalls.any(
          (call) => call.key == 'user_id' && call.value == 'user-1',
        ),
        isTrue,
      );
    });
  });
}
