import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notifications_dao.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/notification_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/notification_repository.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_fixtures.dart';

class MockNotificationsDao extends Mock implements NotificationsDao {}

class MockNotificationRemoteSource extends Mock
    implements NotificationRemoteSource {}

AppNotification _sampleNotification({
  String id = 'notification-1',
  String userId = 'user-1',
}) {
  return AppNotification(id: id, title: 'Title', userId: userId);
}

NotificationSettings _sampleSettings({
  String id = 'settings-1',
  String userId = 'user-1',
}) {
  return NotificationSettings(id: id, userId: userId);
}

void main() {
  late MockNotificationsDao localDao;
  late MockNotificationRemoteSource remoteSource;
  late MockSyncMetadataDao syncDao;
  late NotificationRepository repository;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(_sampleNotification());
    registerFallbackValue(_sampleSettings());
    registerFallbackValue(TestFixtures.sampleSyncMetadata());
  });

  setUp(() {
    localDao = MockNotificationsDao();
    remoteSource = MockNotificationRemoteSource();
    syncDao = MockSyncMetadataDao();

    repository = NotificationRepository(
      localDao: localDao,
      remoteSource: remoteSource,
      syncDao: syncDao,
    );

    when(() => localDao.insertItem(any())).thenAnswer((_) async {});
    when(() => localDao.insertAll(any())).thenAnswer((_) async {});
    when(() => localDao.getById(any())).thenAnswer((_) async => null);
    when(() => localDao.getAll(any())).thenAnswer((_) async => []);
    when(() => localDao.hardDelete(any())).thenAnswer((_) async {});
    when(() => localDao.markAsRead(any())).thenAnswer((_) async {});
    when(() => localDao.markAllAsRead(any())).thenAnswer((_) async {});
    when(() => localDao.upsertSettings(any())).thenAnswer((_) async {});

    when(() => remoteSource.upsert(any())).thenAnswer((_) async {});
    when(() => remoteSource.deleteById(any(), userId: any(named: 'userId'))).thenAnswer((_) async {});
    when(() => remoteSource.fetchAll(any())).thenAnswer((_) async => []);
    when(
      () => remoteSource.fetchUpdatedSince(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => remoteSource.fetchSettings(any())).thenAnswer((_) async => null);

    when(() => syncDao.insertItem(any())).thenAnswer((_) async {});
    when(() => syncDao.insertAll(any())).thenAnswer((_) async {});
    when(() => syncDao.deleteByRecord(any(), any())).thenAnswer((_) async {});
    when(() => syncDao.updateItem(any())).thenAnswer((_) async {});
    when(() => syncDao.getByRecord(any(), any())).thenAnswer((_) async => null);
    when(
      () => syncDao.getPendingByTable(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => syncDao.getPendingRecordIds(any())).thenAnswer((_) async => {});
  });

  group('NotificationRepository', () {
    test('save writes local creates pending metadata and pushes', () async {
      final notification = _sampleNotification(
        id: 'notification-1',
        userId: userId,
      );

      await repository.save(notification);

      verify(() => localDao.insertItem(notification)).called(1);
      verify(() => syncDao.insertItem(any())).called(1);
      verify(() => remoteSource.upsert(notification)).called(1);
    });

    test(
      'remove hard deletes local and creates pendingDelete metadata',
      () async {
        final notification = _sampleNotification(
          id: 'notification-1',
          userId: userId,
        );
        when(
          () => localDao.getById('notification-1'),
        ).thenAnswer((_) async => notification);

        await repository.remove('notification-1');

        verify(() => localDao.hardDelete('notification-1')).called(1);
        final inserted =
            verify(() => syncDao.insertItem(captureAny())).captured.single
                as SyncMetadata;
        expect(inserted.status, SyncStatus.pendingDelete);
        verify(() => remoteSource.deleteById('notification-1', userId: userId)).called(1);
      },
    );

    test('pushAll handles pendingDelete and remote delete', () async {
      final pendingDelete = TestFixtures.sampleSyncMetadata(
        table: SupabaseConstants.notificationsTable,
        userId: userId,
        recordId: 'notification-1',
        status: SyncStatus.pendingDelete,
      );
      when(
        () => syncDao.getPendingByTable(
          userId,
          SupabaseConstants.notificationsTable,
        ),
      ).thenAnswer((_) async => [pendingDelete]);

      await repository.pushAll(userId);

      verify(() => remoteSource.deleteById('notification-1', userId: userId)).called(1);
      verify(
        () => syncDao.deleteByRecord(
          SupabaseConstants.notificationsTable,
          'notification-1',
        ),
      ).called(1);
    });
  });
}
