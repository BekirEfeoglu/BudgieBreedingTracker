import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/event_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/incubation_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';

class MockEventRemoteSource extends Mock implements EventRemoteSource {}

class MockIncubationRemoteSource extends Mock implements IncubationRemoteSource {}

void main() {
  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(
      Event(
        id: 'fallback',
        title: 'fallback',
        eventDate: DateTime(2024, 1, 1),
        type: EventType.custom,
        userId: userId,
      ),
    );
    registerFallbackValue(
      Incubation(
        id: 'fallback',
        userId: userId,
        breedingPairId: 'pair-1',
        startDate: DateTime(2024, 1, 1),
        expectedHatchDate: DateTime(2024, 1, 19),
      ),
    );
  });

  test(
    'hard-deleting an incubation succeeds after hardRemoveByIncubationIds '
    'clears its referencing events',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await db.customStatement(
        "INSERT INTO breeding_pairs (id, user_id, status, is_deleted) "
        "VALUES ('pair-1', '$userId', 'active', 0)",
      );

      final eventRemote = MockEventRemoteSource();
      when(() => eventRemote.upsert(any())).thenAnswer((_) async {});
      final eventRepo = EventRepository(
        localDao: db.eventsDao,
        remoteSource: eventRemote,
        syncDao: db.syncMetadataDao,
        birdsDao: db.birdsDao,
        breedingPairsDao: db.breedingPairsDao,
        chicksDao: db.chicksDao,
        eggsDao: db.eggsDao,
        incubationsDao: db.incubationsDao,
      );

      final incubationRemote = MockIncubationRemoteSource();
      when(() => incubationRemote.upsert(any())).thenAnswer((_) async {});
      final incubationRepo = IncubationRepository(
        localDao: db.incubationsDao,
        remoteSource: incubationRemote,
        syncDao: db.syncMetadataDao,
        breedingPairsDao: db.breedingPairsDao,
        clutchesDao: db.clutchesDao,
      );

      final incubation = Incubation(
        id: 'inc-1',
        userId: userId,
        breedingPairId: 'pair-1',
        startDate: DateTime(2024, 1, 1),
        expectedHatchDate: DateTime(2024, 1, 19),
      );
      await db.incubationsDao.insertItem(incubation);

      final event = Event(
        id: 'evt-1',
        title: 'Egg turn',
        eventDate: DateTime(2024, 1, 2),
        type: EventType.custom,
        userId: userId,
        incubationId: 'inc-1',
      );
      await db.eventsDao.insertItem(event);

      // Mirrors the breeding-pair delete cascade in breeding_form_actions.dart:
      // clear referencing events before hard-deleting the incubation they
      // point at, so PRAGMA foreign_keys=ON doesn't reject the delete.
      await eventRepo.hardRemoveByIncubationIds(['inc-1']);

      // Must not throw "FOREIGN KEY constraint failed".
      await incubationRepo.remove('inc-1');

      expect(await db.incubationsDao.getById('inc-1'), isNull);
      expect(await db.eventsDao.getByIdIncludingDeleted('evt-1'), isNull);
    },
  );

  test(
    'hardRemoveByIncubationIds also purges events that were already '
    'soft-deleted by an earlier incubation-close flow',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await db.customStatement(
        "INSERT INTO breeding_pairs (id, user_id, status, is_deleted) "
        "VALUES ('pair-1', '$userId', 'active', 0)",
      );

      final eventRemote = MockEventRemoteSource();
      when(() => eventRemote.upsert(any())).thenAnswer((_) async {});
      final eventRepo = EventRepository(
        localDao: db.eventsDao,
        remoteSource: eventRemote,
        syncDao: db.syncMetadataDao,
        birdsDao: db.birdsDao,
        breedingPairsDao: db.breedingPairsDao,
        chicksDao: db.chicksDao,
        eggsDao: db.eggsDao,
        incubationsDao: db.incubationsDao,
      );

      final incubationRemote = MockIncubationRemoteSource();
      when(() => incubationRemote.upsert(any())).thenAnswer((_) async {});
      final incubationRepo = IncubationRepository(
        localDao: db.incubationsDao,
        remoteSource: incubationRemote,
        syncDao: db.syncMetadataDao,
        breedingPairsDao: db.breedingPairsDao,
        clutchesDao: db.clutchesDao,
      );

      final incubation = Incubation(
        id: 'inc-1',
        userId: userId,
        breedingPairId: 'pair-1',
        status: IncubationStatus.completed,
        startDate: DateTime(2024, 1, 1),
        expectedHatchDate: DateTime(2024, 1, 19),
      );
      await db.incubationsDao.insertItem(incubation);

      final event = Event(
        id: 'evt-1',
        title: 'Egg turn',
        eventDate: DateTime(2024, 1, 2),
        type: EventType.custom,
        userId: userId,
        incubationId: 'inc-1',
      );
      await db.eventsDao.insertItem(event);

      // Simulates completeBreeding's earlier soft-delete cleanup: the event
      // row survives with isDeleted=true and incubationId still populated.
      await eventRepo.removeByIncubationIds(['inc-1']);

      // Now the pair is deleted too: the incubation gets hard-deleted. The
      // already-soft-deleted event above must not be missed, or its
      // dangling incubationId FK still blocks this delete.
      await eventRepo.hardRemoveByIncubationIds(['inc-1']);
      await incubationRepo.remove('inc-1');

      expect(await db.incubationsDao.getById('inc-1'), isNull);
      expect(await db.eventsDao.getByIdIncludingDeleted('evt-1'), isNull);
    },
  );
}
