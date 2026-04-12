import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/event_reminders_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/events_dao.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/event_reminder_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_reminder_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_fixtures.dart';

class MockEventRemindersDao extends Mock implements EventRemindersDao {}

class MockEventReminderRemoteSource extends Mock
    implements EventReminderRemoteSource {}

class MockEventsDao extends Mock implements EventsDao {}

EventReminder _sampleReminder({
  String id = 'reminder-1',
  String userId = 'user-1',
  String eventId = 'event-1',
  bool isDeleted = false,
}) {
  return EventReminder(
    id: id,
    userId: userId,
    eventId: eventId,
    isDeleted: isDeleted,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  late MockEventRemindersDao localDao;
  late MockEventReminderRemoteSource remoteSource;
  late MockSyncMetadataDao syncDao;
  late MockEventsDao eventsDao;
  late EventReminderRepository repository;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(_sampleReminder());
    registerFallbackValue(TestFixtures.sampleSyncMetadata());
  });

  setUp(() {
    localDao = MockEventRemindersDao();
    remoteSource = MockEventReminderRemoteSource();
    syncDao = MockSyncMetadataDao();
    eventsDao = MockEventsDao();

    repository = EventReminderRepository(
      localDao: localDao,
      remoteSource: remoteSource,
      syncDao: syncDao,
      eventsDao: eventsDao,
    );

    when(() => localDao.insertItem(any())).thenAnswer((_) async {});
    when(() => localDao.insertAll(any())).thenAnswer((_) async {});
    when(() => localDao.softDelete(any())).thenAnswer((_) async {});
    when(() => localDao.hardDelete(any())).thenAnswer((_) async {});
    when(() => localDao.getById(any())).thenAnswer((_) async => null);
    when(() => localDao.getAll(any())).thenAnswer((_) async => []);
    when(
      () => localDao.watchAll(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => localDao.watchByEvent(any()),
    ).thenAnswer((_) => const Stream.empty());

    when(() => remoteSource.upsert(any())).thenAnswer((_) async {});
    when(() => remoteSource.fetchAll(any())).thenAnswer((_) async => []);
    when(
      () => remoteSource.fetchUpdatedSince(any(), any()),
    ).thenAnswer((_) async => []);

    when(() => syncDao.insertItem(any())).thenAnswer((_) async {});
    when(() => syncDao.insertAll(any())).thenAnswer((_) async {});
    when(() => syncDao.deleteByRecord(any(), any())).thenAnswer((_) async {});
    when(
      () => syncDao.getPendingByTable(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => syncDao.getErrorsByTable(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => syncDao.getPendingRecordIds(any())).thenAnswer((_) async => {});
    when(() => syncDao.getByRecord(any(), any())).thenAnswer((_) async => null);
    when(() => syncDao.updateItem(any())).thenAnswer((_) async {});
    when(() => syncDao.hardDelete(any())).thenAnswer((_) async {});
    when(() => eventsDao.getById(any())).thenAnswer(
      (_) async => Event(
        id: 'event-1',
        title: 'Test Event',
        eventDate: DateTime(2024, 1, 1),
        type: EventType.custom,
        userId: userId,
      ),
    );
  });

  group('EventReminderRepository', () {
    test('save writes local, creates pending metadata, and pushes', () async {
      final reminder = _sampleReminder(id: 'reminder-1', userId: userId);

      await repository.save(reminder);

      verify(() => localDao.insertItem(reminder)).called(1);
      verify(() => syncDao.insertItem(any())).called(1);
      verify(() => remoteSource.upsert(reminder)).called(1);
    });

    test('remove soft deletes local and pushes deleted reminder', () async {
      final reminder = _sampleReminder(id: 'reminder-1', userId: userId);
      when(
        () => localDao.getById(reminder.id),
      ).thenAnswer((_) async => reminder);

      await repository.remove(reminder.id);

      verify(() => localDao.softDelete(reminder.id)).called(1);
      final inserted =
          verify(() => syncDao.insertItem(captureAny())).captured.single
              as SyncMetadata;
      expect(inserted.status, SyncStatus.pending);
      expect(inserted.recordId, reminder.id);

      final pushed =
          verify(() => remoteSource.upsert(captureAny())).captured.single
              as EventReminder;
      expect(pushed.id, reminder.id);
      expect(pushed.isDeleted, isTrue);
      expect(pushed.updatedAt, isNotNull);
    });

    test('pull full sync reconciles local rows not found on remote', () async {
      final remote = [_sampleReminder(id: 'remote-1', userId: userId)];
      final orphan = _sampleReminder(id: 'orphan-1', userId: userId);
      final pendingLocal = _sampleReminder(id: 'pending-1', userId: userId);
      when(() => remoteSource.fetchAll(userId)).thenAnswer((_) async => remote);
      when(
        () => localDao.getAll(userId),
      ).thenAnswer((_) async => [remote.first, orphan, pendingLocal]);
      when(
        () => syncDao.getPendingRecordIds(userId),
      ).thenAnswer((_) async => {'pending-1'});

      await repository.pull(userId);

      verify(() => remoteSource.fetchAll(userId)).called(1);
      verify(() => localDao.insertAll(remote)).called(1);
      verify(() => localDao.hardDelete('orphan-1')).called(1);
      verifyNever(() => localDao.hardDelete('pending-1'));
    });

    test('pull rethrows AppException', () async {
      when(
        () => remoteSource.fetchAll(userId),
      ).thenThrow(const DatabaseException('pull failed'));

      expect(() => repository.pull(userId), throwsA(isA<DatabaseException>()));
    });

    test('push marks error metadata when remote upsert fails', () async {
      final reminder = _sampleReminder(id: 'reminder-1', userId: userId);
      final meta = TestFixtures.sampleSyncMetadata(
        table: SupabaseConstants.eventRemindersTable,
        userId: userId,
        recordId: reminder.id,
        retryCount: 1,
      );
      when(
        () => remoteSource.upsert(reminder),
      ).thenThrow(const DatabaseException('remote failed'));
      when(
        () => syncDao.getByRecord(
          SupabaseConstants.eventRemindersTable,
          reminder.id,
        ),
      ).thenAnswer((_) async => meta);

      await repository.push(reminder);

      final updated =
          verify(() => syncDao.updateItem(captureAny())).captured.single
              as SyncMetadata;
      expect(updated.status, SyncStatus.error);
      expect(updated.retryCount, 2);
      expect(updated.errorMessage, 'remote failed');
    });

    test('pushAll pushes only pending records that exist locally', () async {
      final reminder = _sampleReminder(id: 'reminder-1', userId: userId);
      final pending = [
        TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.eventRemindersTable,
          userId: userId,
          recordId: reminder.id,
        ),
        TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.eventRemindersTable,
          userId: userId,
          recordId: 'missing-id',
        ),
      ];
      when(
        () => syncDao.getPendingByTable(
          userId,
          SupabaseConstants.eventRemindersTable,
        ),
      ).thenAnswer((_) async => pending);
      when(
        () => localDao.getById(reminder.id),
      ).thenAnswer((_) async => reminder);
      when(() => localDao.getById('missing-id')).thenAnswer((_) async => null);

      await repository.pushAll(userId);

      verify(() => remoteSource.upsert(reminder)).called(1);
      verify(() => localDao.getById('missing-id')).called(1);
    });
  });
}
