import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/api/feedback_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late RoutingFakeClient client;
  late FeedbackRemoteSource source;

  late FakeFilterBuilder<PostgrestList> feedbackSelectBuilder;
  late FakeFilterBuilder<dynamic> feedbackInsertBuilder;
  late FakeFilterBuilder<PostgrestList> adminSelectBuilder;
  late FakeFilterBuilder<dynamic> notifInsertBuilder;

  setUp(() {
    client = RoutingFakeClient();

    final feedback = client.addTable(SupabaseConstants.feedbackTable);
    feedbackSelectBuilder = feedback.selectBuilder;
    feedbackInsertBuilder = feedback.insertBuilder;

    final admin = client.addTable(SupabaseConstants.adminUsersTable);
    adminSelectBuilder = admin.selectBuilder;

    final notif = client.addTable(SupabaseConstants.notificationsTable);
    notifInsertBuilder = notif.insertBuilder;

    source = FeedbackRemoteSource(client);
  });

  group('fetchByUser', () {
    test('queries feedback table filtered by user_id', () async {
      feedbackSelectBuilder.result = [
        {'id': 'fb-1', 'user_id': 'user-1', 'message': 'Great app'},
      ];

      final result = await source.fetchByUser('user-1');

      expect(result, hasLength(1));
      expect(result.first['id'], 'fb-1');
      expect(client.requestedTables, contains(SupabaseConstants.feedbackTable));
      expect(
        feedbackSelectBuilder.eqCalls.any((e) => e.key == 'user_id'),
        isTrue,
      );
    });

    test('returns empty list when no feedback exists', () async {
      feedbackSelectBuilder.result = [];

      final result = await source.fetchByUser('user-no-data');
      expect(result, isEmpty);
    });

    test('rethrows error on failure', () async {
      feedbackSelectBuilder.error = Exception('Network error');

      expect(
        () => source.fetchByUser('user-1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('insert', () {
    test('inserts data into feedback table', () async {
      feedbackInsertBuilder.result = null;

      await source.insert({
        'user_id': 'user-1',
        'category': 'bug',
        'message': 'Found a bug',
      });

      expect(client.requestedTables, contains(SupabaseConstants.feedbackTable));
    });

    test('rethrows error on failure', () async {
      feedbackInsertBuilder.error = Exception('Insert failed');

      expect(
        () => source.insert({'user_id': 'user-1', 'message': 'test'}),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('notifyFounders', () {
    test('does nothing for empty notification list', () async {
      await source.notifyFounders([]);

      expect(
        client.requestedTables,
        isNot(contains(SupabaseConstants.notificationsTable)),
      );
    });

    test('inserts notifications into notifications table', () async {
      notifInsertBuilder.result = null;

      await source.notifyFounders([
        {'user_id': 'admin-1', 'title': 'New feedback'},
      ]);

      expect(
        client.requestedTables,
        contains(SupabaseConstants.notificationsTable),
      );
    });

    test('swallows errors silently', () async {
      notifInsertBuilder.error = Exception('Insert failed');

      // Should not throw
      await source.notifyFounders([
        {'user_id': 'admin-1', 'title': 'New feedback'},
      ]);
    });
  });

  group('fetchFounderIds', () {
    test('returns founder user IDs', () async {
      adminSelectBuilder.result = [
        {'user_id': 'founder-1'},
        {'user_id': 'founder-2'},
      ];

      final result = await source.fetchFounderIds();

      expect(result, ['founder-1', 'founder-2']);
      expect(
        client.requestedTables,
        contains(SupabaseConstants.adminUsersTable),
      );
    });

    test('filters out null user IDs', () async {
      adminSelectBuilder.result = [
        {'user_id': 'founder-1'},
        {'user_id': null},
      ];

      final result = await source.fetchFounderIds();
      expect(result, ['founder-1']);
    });

    test('returns empty list on error', () async {
      adminSelectBuilder.error = Exception('RLS error');

      final result = await source.fetchFounderIds();
      expect(result, isEmpty);
    });
  });
}
