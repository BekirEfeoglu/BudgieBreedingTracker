import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notification_schedules_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/notification_schedule_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/notification_schedule_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_fixtures.dart';

class MockNotificationSchedulesDao extends Mock
    implements NotificationSchedulesDao {}

class MockNotificationScheduleRemoteSource extends Mock
    implements NotificationScheduleRemoteSource {}

class MockSyncMetadataDao extends Mock implements SyncMetadataDao {}

NotificationSchedule _sampleSchedule({
  String id = 'schedule-1',
  String userId = 'user-1',
}) {
  return NotificationSchedule(
    id: id,
    userId: userId,
    type: NotificationType.custom,
    title: 'Reminder',
    scheduledAt: DateTime(2024, 1, 1, 8),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  late MockNotificationSchedulesDao localDao;
  late MockNotificationScheduleRemoteSource remoteSource;
  late MockSyncMetadataDao syncDao;
  late NotificationScheduleRepository repository;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(_sampleSchedule());
    registerFallbackValue(TestFixtures.sampleSyncMetadata());
  });

  setUp(() {
    localDao = MockNotificationSchedulesDao();
    remoteSource = MockNotificationScheduleRemoteSource();
    syncDao = MockSyncMetadataDao();

    repository = NotificationScheduleRepository(
      localDao: localDao,
      remoteSource: remoteSource,
      syncDao: syncDao,
    );

    when(() => localDao.insertItem(any())).thenAnswer((_) async {});
    when(() => localDao.insertAll(any())).thenAnswer((_) async {});
    when(() => localDao.hardDelete(any())).thenAnswer((_) async {});
    when(() => localDao.getById(any())).thenAnswer((_) async => null);
    when(() => localDao.getAll(any())).thenAnswer((_) async => []);
    when(
      () => localDao.watchAll(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => localDao.watchById(any()),
    ).thenAnswer((_) => const Stream.empty());

    when(() => remoteSource.upsert(any())).thenAnswer((_) async {});
    when(() => remoteSource.fetchAll(any())).thenAnswer((_) async => []);
    when(
      () => remoteSource.fetchUpdatedSince(any(), any()),
    ).thenAnswer((_) async => []);

    when(() => syncDao.insertItem(any())).thenAnswer((_) async {});
    when(() => syncDao.insertAll(any())).thenAnswer((_) async {});
    when(() => syncDao.deleteByRecord(any(), any())).thenAnswer((_) async {});
    when(() => syncDao.getByRecord(any(), any())).thenAnswer((_) async => null);
    when(
      () => syncDao.getPendingByTable(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => syncDao.updateItem(any())).thenAnswer((_) async {});
    when(
      () => syncDao.getPendingRecordIds(any()),
    ).thenAnswer((_) async => <String>{});
  });

  group('NotificationScheduleRepository', () {
    test('save writes local, creates pending metadata, and pushes', () async {
      final schedule = _sampleSchedule(id: 'schedule-1', userId: userId);

      await repository.save(schedule);

      verify(() => localDao.insertItem(schedule)).called(1);
      verify(() => syncDao.insertItem(any())).called(1);
      verify(() => remoteSource.upsert(schedule)).called(1);
    });

    test(
      'saveAll writes all local rows and creates pending sync entries',
      () async {
        final schedules = [
          _sampleSchedule(id: 'schedule-1', userId: userId),
          _sampleSchedule(id: 'schedule-2', userId: userId),
        ];

        await repository.saveAll(schedules);

        verify(() => localDao.insertAll(schedules)).called(1);
        final inserted =
            verify(() => syncDao.insertAll(captureAny())).captured.single
                as List<SyncMetadata>;
        expect(inserted, hasLength(2));
        expect(inserted.every((m) => m.status == SyncStatus.pending), isTrue);
        expect(
          inserted.map((m) => m.recordId),
          containsAll(['schedule-1', 'schedule-2']),
        );
      },
    );

    test('remove hard deletes local row', () async {
      await repository.remove('schedule-1');

      verify(() => localDao.hardDelete('schedule-1')).called(1);
    });

    test('pull full sync fetches all and inserts remote rows', () async {
      final remote = [_sampleSchedule(id: 'remote-1', userId: userId)];
      when(() => remoteSource.fetchAll(userId)).thenAnswer((_) async => remote);

      await repository.pull(userId);

      verify(() => remoteSource.fetchAll(userId)).called(1);
      verify(() => localDao.insertAll(remote)).called(1);
    });

    test('pull rethrows AppException', () async {
      when(
        () => remoteSource.fetchAll(userId),
      ).thenThrow(const DatabaseException('pull failed'));

      expect(() => repository.pull(userId), throwsA(isA<DatabaseException>()));
    });

    test('push marks error metadata when remote upsert fails', () async {
      final schedule = _sampleSchedule(id: 'schedule-1', userId: userId);
      final meta = TestFixtures.sampleSyncMetadata(
        table: SupabaseConstants.notificationSchedulesTable,
        userId: userId,
        recordId: schedule.id,
        retryCount: 3,
      );
      when(
        () => remoteSource.upsert(schedule),
      ).thenThrow(const DatabaseException('remote failed'));
      when(
        () => syncDao.getByRecord(
          SupabaseConstants.notificationSchedulesTable,
          schedule.id,
        ),
      ).thenAnswer((_) async => meta);

      await repository.push(schedule);

      final updated =
          verify(() => syncDao.updateItem(captureAny())).captured.single
              as SyncMetadata;
      expect(updated.status, SyncStatus.error);
      expect(updated.retryCount, 4);
      expect(updated.errorMessage, 'remote failed');
    });

    test('pushAll pushes pending records that exist locally', () async {
      final schedule = _sampleSchedule(id: 'schedule-1', userId: userId);
      final pending = [
        TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.notificationSchedulesTable,
          userId: userId,
          recordId: schedule.id,
        ),
      ];
      when(
        () => syncDao.getPendingByTable(
          userId,
          SupabaseConstants.notificationSchedulesTable,
        ),
      ).thenAnswer((_) async => pending);
      when(
        () => localDao.getById(schedule.id),
      ).thenAnswer((_) async => schedule);

      await repository.pushAll(userId);

      verify(() => remoteSource.upsert(schedule)).called(1);
    });
  });
}
