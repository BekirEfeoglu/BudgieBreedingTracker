import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/api/feedback_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late RoutingFakeClient client;
  late FeedbackRemoteSource source;

  late FakeFilterBuilder<PostgrestList> feedbackSelectBuilder;
  late FakeFilterBuilder<dynamic> feedbackUpsertBuilder;
  late FakeQueryBuilder feedbackQuery;

  setUp(() {
    client = RoutingFakeClient();

    final feedback = client.addTable(SupabaseConstants.feedbackTable);
    feedbackSelectBuilder = feedback.selectBuilder;
    feedbackUpsertBuilder = feedback.upsertBuilder;
    feedbackQuery = feedback.queryBuilder;

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

      expect(() => source.fetchByUser('user-1'), throwsA(isA<Exception>()));
    });
  });

  group('insert', () {
    test('upserts data into feedback table', () async {
      feedbackUpsertBuilder.result = null;

      final data = {
        'user_id': 'user-1',
        'category': 'bug',
        'message': 'Found a bug',
      };

      await source.insert(data);

      expect(client.requestedTables, contains(SupabaseConstants.feedbackTable));
      expect(feedbackQuery.upsertPayload, data);
    });

    test('rethrows error on failure', () async {
      feedbackUpsertBuilder.error = Exception('Upsert failed');

      expect(
        () => source.insert({'user_id': 'user-1', 'message': 'test'}),
        throwsA(isA<Exception>()),
      );
    });
  });
}
