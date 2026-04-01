import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/remote/api/feedback_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/feedback_repository.dart';

class MockFeedbackRemoteSource extends Mock implements FeedbackRemoteSource {}

void main() {
  late MockFeedbackRemoteSource mockRemote;
  late FeedbackRepository repo;

  setUp(() {
    mockRemote = MockFeedbackRemoteSource();
    repo = FeedbackRepository(remoteSource: mockRemote);
  });

  group('FeedbackRepository', () {
    group('fetchByUser', () {
      test('delegates to remote source and returns result', () async {
        final expected = [
          {'id': 'f1', 'subject': 'Bug report'},
          {'id': 'f2', 'subject': 'Feature request'},
        ];
        when(() => mockRemote.fetchByUser('user-1'))
            .thenAnswer((_) async => expected);

        final result = await repo.fetchByUser('user-1');

        expect(result, expected);
        verify(() => mockRemote.fetchByUser('user-1')).called(1);
      });

      test('rethrows on error', () async {
        when(() => mockRemote.fetchByUser(any()))
            .thenThrow(Exception('network error'));

        expect(
          () => repo.fetchByUser('user-1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('submit', () {
      setUp(() {
        when(() => mockRemote.insert(any())).thenAnswer((_) async {});
      });

      test('calls remote insert with correct data', () async {
        final id = await repo.submit(
          userId: 'user-1',
          categoryValue: 'bug',
          subject: 'Test Bug',
          message: 'Description',
          email: 'test@test.com',
          appVersion: '1.0.0',
          deviceInfo: 'iOS 17',
        );

        expect(id, isNotEmpty);

        final captured =
            verify(() => mockRemote.insert(captureAny())).captured.single
                as Map<String, dynamic>;

        expect(captured['user_id'], 'user-1');
        expect(captured['type'], 'bug');
        expect(captured['subject'], 'Test Bug');
        expect(captured['message'], 'Description');
        expect(captured['email'], 'test@test.com');
        expect(captured['app_version'], '1.0.0');
        expect(captured['status'], 'open');
      });

      test('returns generated feedback id', () async {
        final id = await repo.submit(
          userId: 'user-1',
          categoryValue: 'feature',
          subject: 'Request',
          message: 'Details',
        );

        expect(id, isNotEmpty);
        expect(id.length, greaterThan(5));
      });

      test('omits empty email', () async {
        await repo.submit(
          userId: 'user-1',
          categoryValue: 'bug',
          subject: 'Test',
          message: 'Msg',
          email: '',
        );

        final captured =
            verify(() => mockRemote.insert(captureAny())).captured.single
                as Map<String, dynamic>;

        expect(captured.containsKey('email'), isFalse);
      });
    });

    group('notifyFounders', () {
      test('sends notifications to each founder', () async {
        when(() => mockRemote.fetchFounderIds())
            .thenAnswer((_) async => ['admin-1', 'admin-2']);
        when(() => mockRemote.notifyFounders(any()))
            .thenAnswer((_) async {});

        await repo.notifyFounders(
          feedbackId: 'f1',
          notificationTitle: 'New Feedback',
          subject: 'Bug report',
        );

        final captured =
            verify(() => mockRemote.notifyFounders(captureAny()))
                .captured
                .single as List<Map<String, dynamic>>;

        expect(captured.length, 2);
        expect(captured[0]['user_id'], 'admin-1');
        expect(captured[1]['user_id'], 'admin-2');
        expect(captured[0]['title'], 'New Feedback');
        expect(captured[0]['body'], 'Bug report');
      });

      test('skips notification when no founders found', () async {
        when(() => mockRemote.fetchFounderIds())
            .thenAnswer((_) async => []);

        await repo.notifyFounders(
          feedbackId: 'f1',
          notificationTitle: 'Title',
          subject: 'Subject',
        );

        verifyNever(() => mockRemote.notifyFounders(any()));
      });

      test('does not throw when notification fails', () async {
        when(() => mockRemote.fetchFounderIds())
            .thenThrow(Exception('network'));

        // Should not throw — swallows the error
        await repo.notifyFounders(
          feedbackId: 'f1',
          notificationTitle: 'Title',
          subject: 'Subject',
        );
      });
    });
  });
}
