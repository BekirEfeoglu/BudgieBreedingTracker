import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/breeding_pairs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/remote/api/breeding_pair_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';

import '../../helpers/test_fixtures.dart';

class MockBreedingPairsDao extends Mock implements BreedingPairsDao {}

class MockBreedingPairRemoteSource extends Mock
    implements BreedingPairRemoteSource {}

class MockSyncMetadataDao extends Mock implements SyncMetadataDao {}

void main() {
  late MockBreedingPairsDao localDao;
  late MockBreedingPairRemoteSource remoteSource;
  late MockSyncMetadataDao syncDao;
  late BreedingPairRepository repository;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(TestFixtures.sampleBreedingPair());
    registerFallbackValue(TestFixtures.sampleSyncMetadata());
  });

  setUp(() {
    localDao = MockBreedingPairsDao();
    remoteSource = MockBreedingPairRemoteSource();
    syncDao = MockSyncMetadataDao();

    repository = BreedingPairRepository(
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

  group('BreedingPairRepository', () {
    test('save writes local creates pending metadata and pushes', () async {
      final pair = TestFixtures.sampleBreedingPair(
        id: 'pair-1',
        userId: userId,
      );

      await repository.save(pair);

      verify(() => localDao.insertItem(pair)).called(1);
      verify(() => syncDao.insertItem(any())).called(1);
      verify(() => remoteSource.upsert(pair)).called(1);
    });

    test('pull full sync fetches all and inserts local', () async {
      final remote = [TestFixtures.sampleBreedingPair(id: 'pair-remote')];
      when(() => remoteSource.fetchAll(userId)).thenAnswer((_) async => remote);

      await repository.pull(userId);

      verify(() => remoteSource.fetchAll(userId)).called(1);
      verify(() => localDao.insertAll(remote)).called(1);
    });

    test(
      'pushAll pushes all pending records with existing local items',
      () async {
        final pair = TestFixtures.sampleBreedingPair(
          id: 'pair-1',
          userId: userId,
        );
        final pending = TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.breedingPairsTable,
          userId: userId,
          recordId: pair.id,
        );
        when(
          () => syncDao.getPendingByTable(
            userId,
            SupabaseConstants.breedingPairsTable,
          ),
        ).thenAnswer((_) async => [pending]);
        when(() => localDao.getById(pair.id)).thenAnswer((_) async => pair);

        await repository.pushAll(userId);

        verify(() => remoteSource.upsert(pair)).called(1);
      },
    );
  });
}
