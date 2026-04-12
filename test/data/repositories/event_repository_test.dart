import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/events_dao.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/event_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_repository.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_fixtures.dart';

class MockEventsDao extends Mock implements EventsDao {}

class MockEventRemoteSource extends Mock implements EventRemoteSource {}

Event _sampleEvent({String id = 'event-1', String userId = 'user-1'}) {
  return Event(
    id: id,
    title: 'Event',
    eventDate: DateTime(2024, 1, 1),
    type: EventType.custom,
    userId: userId,
  );
}

void main() {
  late MockEventsDao localDao;
  late MockEventRemoteSource remoteSource;
  late MockSyncMetadataDao syncDao;
  late EventRepository repository;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(_sampleEvent());
    registerFallbackValue(TestFixtures.sampleSyncMetadata());
  });

  setUp(() {
    localDao = MockEventsDao();
    remoteSource = MockEventRemoteSource();
    syncDao = MockSyncMetadataDao();

    repository = EventRepository(
      localDao: localDao,
      remoteSource: remoteSource,
      syncDao: syncDao,
    );

    when(() => localDao.insertItem(any())).thenAnswer((_) async {});
    when(() => localDao.insertAll(any())).thenAnswer((_) async {});
    when(() => localDao.getById(any())).thenAnswer((_) async => null);
    when(() => localDao.getAll(any())).thenAnswer((_) async => []);
    when(() => localDao.softDelete(any())).thenAnswer((_) async {});
    when(() => localDao.hardDelete(any())).thenAnswer((_) async => 1);

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
    when(() => syncDao.getPendingRecordIds(any())).thenAnswer((_) async => {});
    when(() => syncDao.getByRecord(any(), any())).thenAnswer((_) async => null);
    when(() => syncDao.updateItem(any())).thenAnswer((_) async {});
  });

  group('EventRepository', () {
    test('save writes local creates pending metadata and pushes', () async {
      final event = _sampleEvent(id: 'event-1', userId: userId);

      await repository.save(event);

      verify(() => localDao.insertItem(event)).called(1);
      verify(() => syncDao.insertItem(any())).called(1);
      verify(() => remoteSource.upsert(event)).called(1);
    });

    test('pull full sync fetches all and inserts local', () async {
      final remote = [_sampleEvent(id: 'event-remote')];
      when(() => remoteSource.fetchAll(userId)).thenAnswer((_) async => remote);

      await repository.pull(userId);

      verify(() => remoteSource.fetchAll(userId)).called(1);
      verify(() => localDao.insertAll(remote)).called(1);
    });

    test(
      'pushAll pushes all pending records with existing local items',
      () async {
        final event = _sampleEvent(id: 'event-1', userId: userId);
        final pending = TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.eventsTable,
          userId: userId,
          recordId: event.id,
        );
        when(
          () =>
              syncDao.getPendingByTable(userId, SupabaseConstants.eventsTable),
        ).thenAnswer((_) async => [pending]);
        when(() => localDao.getById(event.id)).thenAnswer((_) async => event);

        await repository.pushAll(userId);

        verify(() => remoteSource.upsert(event)).called(1);
      },
    );
  });
}
