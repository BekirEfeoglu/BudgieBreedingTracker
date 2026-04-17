import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/health_records_dao.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/health_record_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/health_record_repository.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_fixtures.dart';

class MockHealthRecordsDao extends Mock implements HealthRecordsDao {}

class MockHealthRecordRemoteSource extends Mock
    implements HealthRecordRemoteSource {}

HealthRecord _sampleHealthRecord({
  String id = 'health-1',
  String userId = 'user-1',
  String? birdId,
}) {
  return HealthRecord(
    id: id,
    date: DateTime(2024, 1, 1),
    type: HealthRecordType.checkup,
    title: 'Checkup',
    userId: userId,
    birdId: birdId,
  );
}

void main() {
  late MockHealthRecordsDao localDao;
  late MockHealthRecordRemoteSource remoteSource;
  late MockSyncMetadataDao syncDao;
  late MockBirdsDao birdsDao;
  late HealthRecordRepository repository;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(_sampleHealthRecord());
    registerFallbackValue(TestFixtures.sampleSyncMetadata());
  });

  setUp(() {
    localDao = MockHealthRecordsDao();
    remoteSource = MockHealthRecordRemoteSource();
    syncDao = MockSyncMetadataDao();
    birdsDao = MockBirdsDao();

    repository = HealthRecordRepository(
      localDao: localDao,
      remoteSource: remoteSource,
      syncDao: syncDao,
      birdsDao: birdsDao,
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
    // ValidatedSyncMixin calls clearStaleErrors before pushAll.
    when(
      () => syncDao.getErrorsByTable(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => syncDao.hardDelete(any())).thenAnswer((_) async => 1);
  });

  group('HealthRecordRepository', () {
    test('save writes local creates pending metadata and pushes', () async {
      final record = _sampleHealthRecord(id: 'health-1', userId: userId);

      await repository.save(record);

      verify(() => localDao.insertItem(record)).called(1);
      verify(() => syncDao.insertItem(any())).called(1);
      verify(() => remoteSource.upsert(record)).called(1);
    });

    test('pull full sync fetches all and inserts local', () async {
      final remote = [_sampleHealthRecord(id: 'health-remote')];
      when(() => remoteSource.fetchAll(userId)).thenAnswer((_) async => remote);

      await repository.pull(userId);

      verify(() => remoteSource.fetchAll(userId)).called(1);
      verify(() => localDao.insertAll(remote)).called(1);
    });

    test(
      'pushAll pushes all pending records with existing local items',
      () async {
        final record = _sampleHealthRecord(id: 'health-1', userId: userId);
        final pending = TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.healthRecordsTable,
          userId: userId,
          recordId: record.id,
        );
        when(
          () => syncDao.getPendingByTable(
            userId,
            SupabaseConstants.healthRecordsTable,
          ),
        ).thenAnswer((_) async => [pending]);
        when(() => localDao.getById(record.id)).thenAnswer((_) async => record);

        await repository.pushAll(userId);

        verify(() => remoteSource.upsert(record)).called(1);
      },
    );

    test(
      'pushAll skips record when referenced bird is not found locally',
      () async {
        final record = _sampleHealthRecord(
          id: 'health-1',
          userId: userId,
          birdId: 'missing-bird',
        );
        final pending = TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.healthRecordsTable,
          userId: userId,
          recordId: record.id,
        );
        when(
          () => syncDao.getPendingByTable(
            userId,
            SupabaseConstants.healthRecordsTable,
          ),
        ).thenAnswer((_) async => [pending]);
        when(() => localDao.getById(record.id)).thenAnswer((_) async => record);
        when(
          () => birdsDao.getById('missing-bird'),
        ).thenAnswer((_) async => null);

        final stats = await repository.pushAll(userId);

        verifyNever(() => remoteSource.upsert(any()));
        expect(stats.pushed, 0);
        expect(stats.orphansCleaned, 1);
      },
    );
  });
}
