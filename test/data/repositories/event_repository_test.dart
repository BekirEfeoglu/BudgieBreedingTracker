import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/event_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_repository.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_fixtures.dart';

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
  late MockBirdsDao birdsDao;
  late MockBreedingPairsDao breedingPairsDao;
  late MockChicksDao chicksDao;
  late MockEggsDao eggsDao;
  late MockIncubationsDao incubationsDao;
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
    birdsDao = MockBirdsDao();
    breedingPairsDao = MockBreedingPairsDao();
    chicksDao = MockChicksDao();
    eggsDao = MockEggsDao();
    incubationsDao = MockIncubationsDao();

    repository = EventRepository(
      localDao: localDao,
      remoteSource: remoteSource,
      syncDao: syncDao,
      birdsDao: birdsDao,
      breedingPairsDao: breedingPairsDao,
      chicksDao: chicksDao,
      eggsDao: eggsDao,
      incubationsDao: incubationsDao,
    );

    when(() => localDao.insertItem(any())).thenAnswer((_) async {});
    when(() => localDao.insertAll(any())).thenAnswer((_) async {});
    when(() => localDao.getById(any())).thenAnswer((_) async => null);
    when(() => localDao.getByIdIncludingDeleted(any())).thenAnswer(
      (invocation) =>
          localDao.getById(invocation.positionalArguments.first as String),
    );
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
    when(
      () => syncDao.getErrorsByTable(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => syncDao.hardDelete(any())).thenAnswer((_) async {});

    // FK validator DAOs: default null/empty so non-FK tests pass.
    when(
      () => birdsDao.getByIdIncludingDeleted(any()),
    ).thenAnswer((_) async => null);
    when(
      () => breedingPairsDao.getByIdIncludingDeleted(any()),
    ).thenAnswer((_) async => null);
    when(
      () => chicksDao.getByIdIncludingDeleted(any()),
    ).thenAnswer((_) async => null);
    when(
      () => eggsDao.getByIdIncludingDeleted(any()),
    ).thenAnswer((_) async => null);
    when(() => incubationsDao.getById(any())).thenAnswer((_) async => null);
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

  group('validateForeignKeys via pushAll — egg/incubation', () {
    Event eventWithEgg({String eggId = 'egg-1', String? incubationId}) =>
        _sampleEvent(
          id: 'event-1',
          userId: userId,
        ).copyWith(eggId: eggId, incubationId: incubationId);

    Event eventWithIncubation({String incubationId = 'inc-1'}) =>
        _sampleEvent(id: 'event-1', userId: userId).copyWith(
          incubationId: incubationId,
        );

    Future<void> stubPending(Event event) async {
      final pending = TestFixtures.sampleSyncMetadata(
        table: SupabaseConstants.eventsTable,
        userId: userId,
        recordId: event.id,
      );
      when(
        () => syncDao.getPendingByTable(userId, SupabaseConstants.eventsTable),
      ).thenAnswer((_) async => [pending]);
      when(() => localDao.getById(event.id)).thenAnswer((_) async => event);
      when(
        () => localDao.getByIdIncludingDeleted(event.id),
      ).thenAnswer((_) async => event);
    }

    test(
      'skips push and marks error when referenced egg does not exist locally',
      () async {
        final event = eventWithEgg();
        await stubPending(event);
        when(
          () => eggsDao.getByIdIncludingDeleted('egg-1'),
        ).thenAnswer((_) async => null);

        await repository.pushAll(userId);

        verifyNever(() => remoteSource.upsert(event));
        verify(() => syncDao.insertItem(any())).called(1);
      },
    );

    test(
      'skips push without marking error when referenced egg is a pending tombstone',
      () async {
        final event = eventWithEgg();
        await stubPending(event);
        final deletedEgg = TestFixtures.sampleEgg(
          id: 'egg-1',
        ).copyWith(isDeleted: true);
        when(
          () => eggsDao.getByIdIncludingDeleted('egg-1'),
        ).thenAnswer((_) async => deletedEgg);

        await repository.pushAll(userId);

        verifyNever(() => remoteSource.upsert(event));
      },
    );

    test(
      'skips push without marking error when referenced egg is not yet synced',
      () async {
        final event = eventWithEgg();
        await stubPending(event);
        final egg = TestFixtures.sampleEgg(id: 'egg-1');
        when(
          () => eggsDao.getByIdIncludingDeleted('egg-1'),
        ).thenAnswer((_) async => egg);
        when(
          () => syncDao.getByRecord(SupabaseConstants.eggsTable, 'egg-1'),
        ).thenAnswer(
          (_) async => TestFixtures.sampleSyncMetadata(
            table: SupabaseConstants.eggsTable,
            userId: userId,
            recordId: 'egg-1',
            status: SyncStatus.pending,
          ),
        );

        await repository.pushAll(userId);

        verifyNever(() => remoteSource.upsert(event));
      },
    );

    test('pushes when referenced egg exists and is already synced', () async {
      final event = eventWithEgg();
      await stubPending(event);
      final egg = TestFixtures.sampleEgg(id: 'egg-1');
      when(
        () => eggsDao.getByIdIncludingDeleted('egg-1'),
      ).thenAnswer((_) async => egg);
      when(
        () => syncDao.getByRecord(SupabaseConstants.eggsTable, 'egg-1'),
      ).thenAnswer((_) async => null);

      await repository.pushAll(userId);

      verify(() => remoteSource.upsert(event)).called(1);
    });

    test(
      'skips push and marks error when referenced incubation does not exist locally',
      () async {
        final event = eventWithIncubation();
        await stubPending(event);
        when(
          () => incubationsDao.getById('inc-1'),
        ).thenAnswer((_) async => null);

        await repository.pushAll(userId);

        verifyNever(() => remoteSource.upsert(event));
        verify(() => syncDao.insertItem(any())).called(1);
      },
    );

    test(
      'pushes when referenced incubation exists and is already synced',
      () async {
        final event = eventWithIncubation();
        await stubPending(event);
        final incubation = Incubation(
          id: 'inc-1',
          userId: userId,
          breedingPairId: 'pair-1',
          startDate: DateTime(2024, 1, 1),
          expectedHatchDate: DateTime(2024, 1, 19),
        );
        when(
          () => incubationsDao.getById('inc-1'),
        ).thenAnswer((_) async => incubation);
        when(
          () => syncDao.getByRecord(SupabaseConstants.incubationsTable, 'inc-1'),
        ).thenAnswer((_) async => null);

        await repository.pushAll(userId);

        verify(() => remoteSource.upsert(event)).called(1);
      },
    );
  });
}
